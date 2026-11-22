// Reads and writes an agent's memory files, plan.md and journal.md, in one
// folder per agent. docs/design/memory.md has the design.

import fs from "node:fs";
import path from "node:path";
import YAML from "yaml";

// The format of plan.md and journal.md. A change bumps it and adds a migration,
// as docs/design/versioning.md says.
const SCHEMA_VERSION = 1;

const PLAN_FILE = "plan.md";
const JOURNAL_FILE = "journal.md";

export interface JournalEntry {
	turn: number;
	text: string;
}

export interface Memory {
	plan: string;
	journal: JournalEntry[];
}

type BodyResult =
	| { ok: true; body: string }
	| { ok: false; reason: string };

const FRONT_MATTER = /^---\r?\n(?<yaml>[\s\S]*?)\r?\n---(?:\r?\n|$)/;
// Each journal entry starts with this heading line.
const ENTRY_HEADINGS = /^## Turn (?<turn>\d+)[ \t]*$/gm;

// The caller passes the folder to the other calls, so phase 3 can point them
// at a restored snapshot.
export function memoryFolder(configFile: string, playerID: number): string {
	return path.join(path.dirname(configFile), "memory", `player-${playerID}`);
}

// Returns the agent's memory, and a warning for each file it couldn't read.
// Call it before addJournalEntry, so a file it can't read is already aside.
export function readMemory(folder: string, now: Date): { memory: Memory; warnings: string[] } {
	const warnings: string[] = [];
	const plan = readFile(folder, PLAN_FILE, now, warnings).trim();
	const journal = parseJournal(readFile(folder, JOURNAL_FILE, now, warnings));

	return { memory: { plan, journal }, warnings };
}

export function writePlan(folder: string, plan: string): void {
	fs.mkdirSync(folder, { recursive: true });
	fs.writeFileSync(path.join(folder, PLAN_FILE), withFrontMatter(`${plan.trim()}\n`));
}

// Appends to the file, so an entry costs the same however long the journal
// grows.
export function addJournalEntry(folder: string, entry: JournalEntry): void {
	const file = path.join(folder, JOURNAL_FILE);

	fs.mkdirSync(folder, { recursive: true });

	if (!fs.existsSync(file)) {
		fs.writeFileSync(file, withFrontMatter(""));
	}

	fs.appendFileSync(file, formatEntry(entry));
}

// Reads one memory file's body. A missing file reads as empty. A file the store
// can't read moves aside with a warning, so a later write can't replace it.
function readFile(folder: string, name: string, now: Date, warnings: string[]): string {
	const file = path.join(folder, name);

	if (!fs.existsSync(file)) {
		return "";
	}

	const result = readBody(fs.readFileSync(file, "utf8"));

	if (result.ok) {
		return result.body;
	}

	// toISOString gives colons, which Windows forbids in file names.
	const aside = `${file}.unreadable-${now.toISOString().replace(/[:.]/g, "-")}`;

	fs.renameSync(file, aside);
	warnings.push(`Couldn't read ${file}, because ${result.reason}. The agent starts with an empty ${name}, and the old file is at ${aside}`);

	return "";
}

function withFrontMatter(body: string): string {
	return `---\nschemaVersion: ${SCHEMA_VERSION}\n---\n${body}`;
}

// Splits off the front matter and checks its schema version. A file someone
// edited by hand can lose it, so a missing one is a reason, not an exception.
function readBody(text: string): BodyResult {
	const match = FRONT_MATTER.exec(text);

	if (!match?.groups) {
		return { ok: false, reason: "it has no front matter with a schema version" };
	}

	let version: unknown;

	try {
		version = (YAML.parse(match.groups.yaml) as { schemaVersion?: unknown } | null)?.schemaVersion;
	} catch (error) {
		return { ok: false, reason: `its front matter isn't valid YAML: ${(error as Error).message}` };
	}

	if (version !== SCHEMA_VERSION) {
		return { ok: false, reason: `its schema version is ${JSON.stringify(version)}, and this bridge reads ${SCHEMA_VERSION}` };
	}

	return { ok: true, body: text.slice(match[0].length) };
}

// A line in the text that looks like an entry heading gets a backslash, so the
// next read doesn't split the entry there. Markdown shows it as plain text.
function formatEntry(entry: JournalEntry): string {
	return `\n## Turn ${entry.turn}\n\n${entry.text.trim().replace(ENTRY_HEADINGS, String.raw`\$&`)}\n`;
}

// Text before the first heading belongs to no turn, so the store drops it.
function parseJournal(body: string): JournalEntry[] {
	const headings = [...body.matchAll(ENTRY_HEADINGS)];

	return headings.map((heading, index) => ({
		turn: Number(heading.groups?.turn),
		text: body.slice(heading.index + heading[0].length, headings[index + 1]?.index).trim(),
	}));
}
