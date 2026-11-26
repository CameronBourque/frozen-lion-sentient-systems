// Tests for prompt.ts, with the knowledge files that ship with the bridge.

import path from "node:path";
import { describe, expect, test } from "vitest";
import { DEFAULT_PROFILE, systemPrompt, turnMessage } from "../../src/agents/prompt.js";
import { knowledgeFromFolder } from "../../src/knowledge.js";
import type { Memory } from "../../src/memory/store.js";
import type { State } from "../../src/state/state.js";
import type { TunerClient } from "../../src/tuner/client.js";
import { connectTools } from "../mcp/tools.js";
import { MINIMAL_STATE } from "../state/minimal-state.js";

const KNOWLEDGE = knowledgeFromFolder(path.join(import.meta.dirname, "..", "..", "knowledge"));

describe("systemPrompt", () => {
	test("holds the rules of play, the personality, and the sweat level, in that order", () => {
		const { text, warnings } = systemPrompt(KNOWLEDGE, DEFAULT_PROFILE);
		const starts = ["# Rules of play", "# Neutral", "# Balanced"].map((heading) => text.indexOf(heading));

		expect(warnings).toEqual([]);
		expect(starts[0]).toBe(0);
		expect(starts).toEqual([...starts].sort((a, b) => a - b));
	});

	test("falls back to the default for each name with no file, with a warning", () => {
		const { text, warnings } = systemPrompt(KNOWLEDGE, { personality: "pirate", sweatLevel: "frantic" });

		expect(text).toBe(systemPrompt(KNOWLEDGE, DEFAULT_PROFILE).text);
		expect(warnings).toEqual([
			"There is no personalities/pirate.md, so the agent uses neutral",
			"There is no sweat/frantic.md, so the agent uses balanced",
		]);
	});

	test("leaves out a file that is missing", () => {
		const knowledge = new Map([...KNOWLEDGE].filter(([file]) => file !== "rules/play.md"));

		expect(systemPrompt(knowledge, DEFAULT_PROFILE).text.startsWith("# Neutral")).toBe(true);
	});

	test("names only tools that the MCP server has", async () => {
		const { tools } = await (await connectTools({} as TunerClient)).listTools();
		const named = [...(KNOWLEDGE.get("rules/play.md") ?? "").matchAll(/`([a-z]+(?:_[a-z]+)+)`/g)].map(([, name]) => name);

		expect(named).toContain("end_turn");
		expect(named.filter((name) => !tools.some((tool) => tool.name === name))).toEqual([]);
	});
});

describe("turnMessage", () => {
	// The state part, which leaves out the turn and the blockers.
	function statePart(state: State): string {
		const rest: Partial<State> = { ...state };

		delete rest.turn;
		delete rest.blockers;

		return `## State\n\n${JSON.stringify(rest)}`;
	}

	const NO_MEMORY: Memory = { plan: "", journal: [], decisions: [] };
	const JOURNAL = [{ turn: 3, text: "Met Rome." }, { turn: 4, text: "Rome denounced us." }, { turn: 6, text: "Settled the coast." }];

	function message(state = MINIMAL_STATE, memory = NO_MEMORY, journalEntries = 10, again = false): string {
		return turnMessage({ state, memory, journalEntries, again });
	}

	test("holds the turn, the plan, the journal, the blockers, and the rest of the state, in that order", () => {
		expect(message(MINIMAL_STATE, { ...NO_MEMORY, plan: "Take the coast.", journal: JOURNAL.slice(0, 1) })).toBe([
			"# Turn 1\n\nIt's your turn.",
			"## Your plan\n\nTake the coast.",
			"## Your journal\n\n### Turn 3\n\nMet Rome.",
			"## End-turn blockers\n\n- ENDTURN_BLOCKING_RESEARCH",
			statePart(MINIMAL_STATE),
		].join("\n\n"));
	});

	test("says a turn that started again is still the same turn, and asks for end_turn again", () => {
		const text = message(MINIMAL_STATE, NO_MEMORY, 10, true);

		expect(text).toMatch(/^# Turn 1\n\nThe game cancelled your end turn, so this is still the same turn\..*call end_turn again\.\n\n## Your plan/s);
		expect(text).not.toContain("It's your turn.");
	});

	test("asks for a plan and an entry when memory is empty", () => {
		expect(message()).toContain("## Your plan\n\nYou have no plan yet. Make one with update_plan.\n\n## Your journal\n\nNo entries yet. Add one with add_journal_entry");
	});

	test("holds only the newest entries, oldest first, and says how many it left out", () => {
		expect(message(MINIMAL_STATE, { ...NO_MEMORY, journal: JOURNAL }, 2)).toContain("## Your journal\n\nYour newest 2 of 3 entries.\n\n### Turn 4\n\nRome denounced us.\n\n### Turn 6\n\nSettled the coast.\n\n## End-turn blockers");
	});

	test("holds no entries when the cap is 0", () => {
		expect(message(MINIMAL_STATE, { ...NO_MEMORY, journal: JOURNAL }, 0)).toContain("## Your journal\n\nNo entries yet.");
	});

	test("names each blocker's choice and the units that need orders", () => {
		const state = { ...MINIMAL_STATE, blockers: { list: [{ type: "ENDTURN_BLOCKING_RESEARCH", choice: "techs" }], units: [12, 15] } };

		expect(message(state)).toContain("- ENDTURN_BLOCKING_RESEARCH, resolved by techs in get_choices\n- Units that need orders: 12, 15");
	});

	test("says when nothing blocks the turn", () => {
		expect(message({ ...MINIMAL_STATE, blockers: { list: [], units: [] } })).toContain("None. End the turn when your other actions are done.");
	});

	describe("last turn's decisions", () => {
		const DECISIONS = [
			{ id: 1, turn: 3, decision: "Settle the coast.", reason: "Fish and a harbor.", result: "The city grew fast." },
			{ id: 2, turn: 5, decision: "Declare war on Rome.", reason: "Their capital is weak." },
			{ id: 3, turn: 5, decision: "Pick Oligarchy.", reason: "Combat strength.", result: "Units hit harder." },
			{ id: 4, turn: 5, decision: "Build a wall.", reason: "Rome is close." },
			{ id: 5, turn: 6, decision: "Raze the camp.", reason: "Barbarians." },
		];

		test("lists the records of the last turn before this one that have no result, after the journal", () => {
			expect(message({ ...MINIMAL_STATE, turn: 6 }, { ...NO_MEMORY, decisions: DECISIONS })).toContain([
				"## Your journal\n\nNo entries yet. Add one with add_journal_entry when something happens that a later turn needs to know.",
				"## Last turn's decisions\n\nRecord the short-term result of each with record_result and its id.\n\n- 2: Declare war on Rome. Reason: Their capital is weak.\n- 4: Build a wall. Reason: Rome is close.",
				"## End-turn blockers",
			].join("\n\n"));
		});

		test("leaves the part out when every record of the last turn has a result", () => {
			expect(message({ ...MINIMAL_STATE, turn: 4 }, { ...NO_MEMORY, decisions: DECISIONS })).not.toContain("## Last turn's decisions");
		});

		test("leaves the part out when no record is from an earlier turn", () => {
			expect(message({ ...MINIMAL_STATE, turn: 3 }, { ...NO_MEMORY, decisions: DECISIONS })).not.toContain("## Last turn's decisions");
		});
	});
});
