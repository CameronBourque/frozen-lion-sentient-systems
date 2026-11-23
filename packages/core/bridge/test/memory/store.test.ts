// Tests for store.ts.

import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { afterEach, beforeEach, describe, expect, test } from "vitest";
import { addDecision, addJournalEntry, memoryFolder, readMemory, setDecisionResult, startMemory, writePlan } from "../../src/memory/store.js";

const NOW = new Date("2026-11-21T10:20:30.456Z");
const STAMP = "2026-11-21T10-20-30-456Z";
const HEADER = "---\nschemaVersion: 1\n---\n";

let folder: string;

beforeEach(() => {
	folder = path.join(fs.mkdtempSync(path.join(os.tmpdir(), "memory-")), "player-0");
});

afterEach(() => {
	fs.rmSync(path.dirname(folder), { recursive: true, force: true });
});

function writeFile(name: string, text: string): void {
	fs.mkdirSync(folder, { recursive: true });
	fs.writeFileSync(path.join(folder, name), text);
}

describe("memoryFolder", () => {
	test("puts each player's folder under memory, next to the config file", () => {
		const config = path.resolve("/games/bridge/sentient-systems.yaml");

		expect(memoryFolder(config, 3)).toBe(path.resolve("/games/bridge/memory/player-3"));
	});
});

describe("readMemory", () => {
	test("reads a missing folder as empty memory", () => {
		expect(readMemory(folder, NOW)).toEqual({ memory: { plan: "", journal: [], decisions: [] }, warnings: [] });
	});

	test("reads a file with Windows line endings", () => {
		writeFile("plan.md", "---\r\nschemaVersion: 1\r\n---\r\nTake the coast.\r\n");

		expect(readMemory(folder, NOW).memory.plan).toBe("Take the coast.");
	});

	test("drops journal text before the first entry", () => {
		writeFile("journal.md", `${HEADER}A note with no turn.\n\n## Turn 4\n\nMet Rome.\n`);

		expect(readMemory(folder, NOW).memory.journal).toEqual([{ turn: 4, text: "Met Rome." }]);
	});

	test.each([
		["no front matter", "Take the coast.\n", "it has no front matter with a schema version"],
		["empty front matter", "---\n\n---\nTake the coast.\n", "its schema version is undefined"],
		["a newer schema version", "---\nschemaVersion: 2\n---\nTake the coast.\n", "its schema version is 2, and this bridge reads 1"],
		["front matter that isn't YAML", "---\nschemaVersion: [1\n---\nTake the coast.\n", "its front matter isn't valid YAML"],
	])("moves aside a file with %s, and warns", (_, text, reason) => {
		writeFile("plan.md", text);

		const { memory, warnings } = readMemory(folder, NOW);
		const aside = path.join(folder, `plan.md.unreadable-${STAMP}`);

		expect(memory.plan).toBe("");
		expect(warnings).toEqual([expect.stringContaining(reason)]);
		expect(warnings[0]).toContain(aside);
		expect(fs.readFileSync(aside, "utf8")).toBe(text);
		expect(fs.existsSync(path.join(folder, "plan.md"))).toBe(false);
	});

	test("keeps a moved-aside journal when a new entry comes", () => {
		writeFile("journal.md", "## Turn 4\n\nMet Rome.\n");
		readMemory(folder, NOW);
		addJournalEntry(folder, { turn: 5, text: "Settled a second city." });

		expect(fs.readFileSync(path.join(folder, `journal.md.unreadable-${STAMP}`), "utf8")).toBe("## Turn 4\n\nMet Rome.\n");
		expect(readMemory(folder, NOW).memory.journal).toEqual([{ turn: 5, text: "Settled a second city." }]);
	});
});

describe("startMemory", () => {
	const aside = (): string => `${folder}.old-${STAMP}`;

	test("starts a new agent with empty memory", () => {
		expect(startMemory(folder, 1, NOW)).toEqual({ memory: { plan: "", journal: [], decisions: [] }, warnings: [] });
		expect(fs.existsSync(aside())).toBe(false);
	});

	test("keeps memory from this turn and earlier ones", () => {
		writePlan(folder, "Take the coast.");
		addJournalEntry(folder, { turn: 4, text: "Met Rome." });
		addJournalEntry(folder, { turn: 5, text: "Settled a second city." });

		expect(startMemory(folder, 5, NOW)).toEqual({
			memory: { plan: "Take the coast.", journal: [{ turn: 4, text: "Met Rome." }, { turn: 5, text: "Settled a second city." }], decisions: [] },
			warnings: [],
		});
	});

	test("moves aside memory from a later turn, and warns", () => {
		writePlan(folder, "Take the coast.");
		addJournalEntry(folder, { turn: 50, text: "Took Rome." });

		const { memory, warnings } = startMemory(folder, 30, NOW);

		expect(memory).toEqual({ plan: "", journal: [], decisions: [] });
		expect(warnings).toEqual([expect.stringContaining(aside())]);
		expect(fs.existsSync(folder)).toBe(false);
		expect(readMemory(aside(), NOW).memory).toEqual({ plan: "Take the coast.", journal: [{ turn: 50, text: "Took Rome." }], decisions: [] });
	});

	test("moves aside a plan alone on turn 1, since a new game has none yet", () => {
		writePlan(folder, "Take the coast.");

		expect(startMemory(folder, 1, NOW).memory).toEqual({ plan: "", journal: [], decisions: [] });
		expect(readMemory(aside(), NOW).memory.plan).toBe("Take the coast.");
	});

	test("keeps the warning about a file it couldn't read", () => {
		writeFile("plan.md", "Take the coast.\n");
		addJournalEntry(folder, { turn: 50, text: "Took Rome." });

		const { warnings } = startMemory(folder, 30, NOW);

		expect(warnings).toEqual([expect.stringContaining("no front matter"), expect.stringContaining(aside())]);
		expect(fs.existsSync(path.join(aside(), `plan.md.unreadable-${STAMP}`))).toBe(true);
	});

	test("moves aside a decision record from a later turn", () => {
		addDecision(folder, [], { turn: 50, decision: "Declare war on Rome.", reason: "Their capital is weak." });

		expect(startMemory(folder, 30, NOW).memory).toEqual({ plan: "", journal: [], decisions: [] });
		expect(fs.existsSync(aside())).toBe(true);
	});
});

describe("decision records", () => {
	const WAR = { turn: 5, decision: "Declare war on Rome.", reason: "Their capital is weak." };
	const WALL = { turn: 5, decision: "Build a wall.", reason: "Rome is close." };

	function decisions(): ReturnType<typeof readMemory>["memory"]["decisions"] {
		return readMemory(folder, NOW).memory.decisions;
	}

	test("appends one JSON line per record, with the schema version and the next id", () => {
		expect(addDecision(folder, [], WAR)).toBe(1);
		expect(addDecision(folder, decisions(), WALL)).toBe(2);

		expect(fs.readFileSync(path.join(folder, "decisions.jsonl"), "utf8")).toBe([
			`{"schemaVersion":1,"id":1,"turn":5,"decision":"Declare war on Rome.","reason":"Their capital is weak."}`,
			`{"schemaVersion":1,"id":2,"turn":5,"decision":"Build a wall.","reason":"Rome is close."}`,
			"",
		].join("\n"));
		expect(decisions()).toEqual([{ id: 1, ...WAR }, { id: 2, ...WALL }]);
	});

	test("sets the result of the record with the id, and keeps the others", () => {
		addDecision(folder, [], WAR);
		addDecision(folder, decisions(), WALL);

		expect(setDecisionResult(folder, decisions(), 1, "Took two cities.")).toBe(true);
		expect(decisions()).toEqual([{ id: 1, ...WAR, result: "Took two cities." }, { id: 2, ...WALL }]);
	});

	test("changes nothing for an id no record has", () => {
		addDecision(folder, [], WAR);

		expect(setDecisionResult(folder, decisions(), 7, "Took two cities.")).toBe(false);
		expect(decisions()).toEqual([{ id: 1, ...WAR }]);
	});

	test("reads a file with Windows line endings", () => {
		writeFile("decisions.jsonl", `{"schemaVersion":1,"id":1,"turn":5,"decision":"Build a wall.","reason":"Rome is close."}\r\n`);

		expect(decisions()).toEqual([{ id: 1, ...WALL }]);
	});

	test.each([
		["a line that isn't JSON", `{"schemaVersion":1,`, "a line isn't valid JSON"],
		["a newer schema version", `{"schemaVersion":2,"id":1,"turn":5,"decision":"Build a wall.","reason":"Rome is close."}`, "the record on its line 1 isn't a decision record of schema version 1"],
	])("moves aside a file with %s, and warns", (_, line, reason) => {
		writeFile("decisions.jsonl", `${line}\n`);

		const { memory, warnings } = readMemory(folder, NOW);

		expect(memory.decisions).toEqual([]);
		expect(warnings).toEqual([expect.stringContaining(reason)]);
		expect(fs.existsSync(path.join(folder, `decisions.jsonl.unreadable-${STAMP}`))).toBe(true);
	});
});

describe("writePlan", () => {
	test("writes the plan after the front matter, in a new folder", () => {
		writePlan(folder, "  Take the coast.\n\n");

		expect(fs.readFileSync(path.join(folder, "plan.md"), "utf8")).toBe(`${HEADER}Take the coast.\n`);
	});

	test("replaces the last plan", () => {
		writePlan(folder, "Take the coast.");
		writePlan(folder, "Build a navy.");

		expect(readMemory(folder, NOW).memory.plan).toBe("Build a navy.");
	});
});

describe("addJournalEntry", () => {
	test("appends entries in order, under a heading with the turn", () => {
		addJournalEntry(folder, { turn: 1, text: "Founded the capital." });
		addJournalEntry(folder, { turn: 2, text: "Met Rome.\n\nThey seem friendly." });

		expect(fs.readFileSync(path.join(folder, "journal.md"), "utf8")).toBe(`${HEADER}\n## Turn 1\n\nFounded the capital.\n\n## Turn 2\n\nMet Rome.\n\nThey seem friendly.\n`);
		expect(readMemory(folder, NOW).memory.journal).toEqual([
			{ turn: 1, text: "Founded the capital." },
			{ turn: 2, text: "Met Rome.\n\nThey seem friendly." },
		]);
	});

	test("keeps an entry whole when its text holds a line like a heading", () => {
		addJournalEntry(folder, { turn: 9, text: "Looked back.\n## Turn 3\nThat was a mistake." });

		expect(readMemory(folder, NOW).memory.journal).toEqual([{ turn: 9, text: String.raw`Looked back.
\## Turn 3
That was a mistake.` }]);
	});

	test("lets a heading-like phrase inside a line through", () => {
		addJournalEntry(folder, { turn: 9, text: "See ## Turn 3 above." });

		expect(readMemory(folder, NOW).memory.journal).toEqual([{ turn: 9, text: "See ## Turn 3 above." }]);
	});
});
