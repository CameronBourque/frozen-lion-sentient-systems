// Reads and writes an agent's memory files, plan.md, journal.md, and
// decisions.jsonl, in one folder per agent. docs/design/memory.md has the
// design.

import fs from "node:fs";
import path from "node:path";
import YAML from "yaml";
import { z } from "zod";

// The format of the memory files. A change bumps it and adds a migration, as
// docs/design/versioning.md says.
const SCHEMA_VERSION = 1;

const PLAN_FILE = "plan.md";
const JOURNAL_FILE = "journal.md";
const DECISIONS_FILE = "decisions.jsonl";

export interface JournalEntry {
	turn: number;
	text: string;
}

// A record as the agent sees it. id counts from 1 in the file. Not strict, so
// parsing a line with it drops the schema version.
const DECISION = z.object({
	id: z.int().min(1),
	turn: z.int().min(0),
	decision: z.string(),
	reason: z.string(),
	result: z.string().optional(),
});

// One line of decisions.jsonl. Each line carries the schema version, so every
// line is JSON on its own.
const DECISION_LINE = z.strictObject({ schemaVersion: z.literal(SCHEMA_VERSION), ...DECISION.shape });

export type DecisionRecord = z.infer<typeof DECISION>;

export interface Memory {
	plan: string;
	journal: JournalEntry[];
	decisions: DecisionRecord[];
}

const EMPTY: Memory = { plan: "", journal: [], decisions: [] };

type ReadResult<T> =
	| { ok: true; value: T }
	| { ok: false; reason: string };

const FRONT_MATTER = /^---\r?\n(?<yaml>[\s\S]*?)\r?\n---(?:\r?\n|$)/;
// Each journal entry starts with this heading line.
const ENTRY_HEADINGS = /^## Turn (?<turn>\d+)[ \t]*$/gm;

// The caller passes the folder to the other calls, so phase 4 can point them
// at a restored snapshot.
export function memoryFolder(configFile: string, playerID: number): string {
	return path.join(path.dirname(configFile), "memory", `player-${playerID}`);
}

// Returns the agent's memory, and a warning for each file it couldn't read.
// Call it before a write, so a file it can't read is already aside.
export function readMemory(folder: string, now: Date): { memory: Memory; warnings: string[] } {
	const warnings: string[] = [];
	const read = <T>(name: string, parse: (text: string) => ReadResult<T>, empty: T): T => readFile(folder, name, parse, now, warnings) ?? empty;

	return {
		memory: {
			plan: read(PLAN_FILE, (text) => mapBody(text, (body) => body.trim()), EMPTY.plan),
			journal: read(JOURNAL_FILE, (text) => mapBody(text, parseJournal), EMPTY.journal),
			decisions: read(DECISIONS_FILE, parseDecisions, EMPTY.decisions),
		},
		warnings,
	};
}

// Reads the memory for the agent's first turn after the bridge starts. Memory
// from a turn after this one, or any memory on turn 1, belongs to another game
// or a later save, so the folder moves aside and the agent starts empty. The
// checkpoint IDs replace this, as docs/roadmap/phase-4/README.md says.
export function startMemory(folder: string, turn: number, now: Date): { memory: Memory; warnings: string[] } {
	const read = readMemory(folder, now);

	if (!isStale(read.memory, turn)) {
		return read;
	}

	const aside = `${folder}.old-${timeStamp(now)}`;

	fs.renameSync(folder, aside);
	read.warnings.push(`The memory in ${folder} is from another game or a later turn than ${turn}, so the agent starts with empty memory. The old memory is at ${aside}`);

	return { memory: EMPTY, warnings: read.warnings };
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

// Appends a record with the next id, and returns the id. decisions is the list
// that readMemory returned.
export function addDecision(folder: string, decisions: DecisionRecord[], record: Omit<DecisionRecord, "id" | "result">): number {
	const id = (decisions.at(-1)?.id ?? 0) + 1;

	fs.mkdirSync(folder, { recursive: true });
	fs.appendFileSync(path.join(folder, DECISIONS_FILE), formatDecision({ id, ...record }));

	return id;
}

// Sets the result of the record with the id, and rewrites the file. Returns
// false when no record has the id.
export function setDecisionResult(folder: string, decisions: DecisionRecord[], id: number, result: string): boolean {
	if (!decisions.some((record) => record.id === id)) {
		return false;
	}

	const updated = decisions.map((record) => (record.id === id ? { ...record, result } : record));

	fs.writeFileSync(path.join(folder, DECISIONS_FILE), updated.map(formatDecision).join(""));

	return true;
}

// Reads and parses one memory file. A missing file returns undefined. A file
// the store can't read moves aside with a warning, so a later write can't
// replace it, and returns undefined.
function readFile<T>(folder: string, name: string, parse: (text: string) => ReadResult<T>, now: Date, warnings: string[]): T | undefined {
	const file = path.join(folder, name);

	if (!fs.existsSync(file)) {
		return undefined;
	}

	const result = parse(fs.readFileSync(file, "utf8"));

	if (result.ok) {
		return result.value;
	}

	const aside = `${file}.unreadable-${timeStamp(now)}`;

	fs.renameSync(file, aside);
	warnings.push(`Couldn't read ${file}, because ${result.reason}. The agent starts with an empty ${name}, and the old file is at ${aside}`);

	return undefined;
}

function isStale(memory: Memory, turn: number): boolean {
	const empty = memory.plan === "" && memory.journal.length === 0 && memory.decisions.length === 0;
	const turns = [...memory.journal, ...memory.decisions].map((item) => item.turn);

	return (turn === 1 && !empty) || turns.some((itemTurn) => itemTurn > turn);
}

// The time for a file or folder name. toISOString gives colons, which Windows
// forbids in file names.
function timeStamp(now: Date): string {
	return now.toISOString().replace(/[:.]/g, "-");
}

function withFrontMatter(body: string): string {
	return `---\nschemaVersion: ${SCHEMA_VERSION}\n---\n${body}`;
}

// Splits off the front matter, checks its schema version, and parses the rest.
// A file someone edited by hand can lose the front matter, so a missing one is
// a reason, not an exception.
function mapBody<T>(text: string, parse: (body: string) => T): ReadResult<T> {
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

	return { ok: true, value: parse(text.slice(match[0].length)) };
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

function formatDecision(record: DecisionRecord): string {
	return `${JSON.stringify({ schemaVersion: SCHEMA_VERSION, ...record })}\n`;
}

// Every line must parse, so the ids and results the agent sees match the file.
function parseDecisions(text: string): ReadResult<DecisionRecord[]> {
	const records: DecisionRecord[] = [];

	for (const [index, line] of text.split(/\r?\n/).entries()) {
		if (line.trim() === "") {
			continue;
		}

		let parsed: ReturnType<typeof DECISION_LINE.safeParse>;

		try {
			parsed = DECISION_LINE.safeParse(JSON.parse(line));
		} catch (error) {
			return { ok: false, reason: `a line isn't valid JSON: ${(error as Error).message}` };
		}

		if (!parsed.success) {
			return { ok: false, reason: `the record on its line ${index + 1} isn't a decision record of schema version ${SCHEMA_VERSION}` };
		}

		records.push(DECISION.parse(parsed.data));
	}

	return { ok: true, value: records };
}
