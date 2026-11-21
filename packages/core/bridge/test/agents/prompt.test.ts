// Tests for prompt.ts, with the knowledge files that ship with the bridge.

import path from "node:path";
import { describe, expect, test } from "vitest";
import { DEFAULT_PROFILE, systemPrompt, turnMessage } from "../../src/agents/prompt.js";
import { knowledgeFromFolder } from "../../src/knowledge.js";
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

	test("holds the turn, the blockers, and the rest of the state, in that order", () => {
		expect(turnMessage(MINIMAL_STATE)).toBe([
			"# Turn 1\n\nIt's your turn.",
			"## End-turn blockers\n\n- ENDTURN_BLOCKING_RESEARCH",
			statePart(MINIMAL_STATE),
		].join("\n\n"));
	});

	test("names each blocker's choice and the units that need orders", () => {
		const state = { ...MINIMAL_STATE, blockers: { list: [{ type: "ENDTURN_BLOCKING_RESEARCH", choice: "techs" }], units: [12, 15] } };

		expect(turnMessage(state)).toContain("- ENDTURN_BLOCKING_RESEARCH, resolved by techs in get_choices\n- Units that need orders: 12, 15");
	});

	test("says when nothing blocks the turn", () => {
		expect(turnMessage({ ...MINIMAL_STATE, blockers: { list: [], units: [] } })).toContain("None. End the turn when your other actions are done.");
	});
});
