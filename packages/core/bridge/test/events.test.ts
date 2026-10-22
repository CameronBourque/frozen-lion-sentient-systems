// Tests for events.ts.

import { describe, expect, test } from "vitest";
import { KINDS, parseLine, stripState } from "../src/events.js";

describe("stripState", () => {
	test("removes the state prefix", () => {
		expect(stripState("SentientSystemsCore_UI: [SENTIENTSYSTEMS] AGENT_TURN 0")).toBe("[SENTIENTSYSTEMS] AGENT_TURN 0");
	});

	test("leaves a line with no prefix unchanged", () => {
		expect(stripState("[SENTIENTSYSTEMS] AGENT_TURN 0")).toBe("[SENTIENTSYSTEMS] AGENT_TURN 0");
	});

	test("removes only the first prefix", () => {
		expect(stripState("InGame: PlotInfo: x")).toBe("PlotInfo: x");
	});
});

describe("parseLine", () => {
	test.each(KINDS)("parses the $name example", ({ example }) => {
		expect(parseLine(example).result).toBe("event");
	});

	test("reads the player ID of a turn line", () => {
		expect(parseLine("[SENTIENTSYSTEMS] AGENT_TURN 12")).toEqual({ result: "event", event: { type: "turn", playerId: 12 } });
	});

	test.each([
		{ name: "a game print", line: "PlotInfo::OnCitySelectionChanged" },
		{ name: "an empty line", line: "" },
		{ name: "the tag inside a line", line: "said [SENTIENTSYSTEMS] AGENT_TURN 0" },
		{ name: "the tag with no space after it", line: "[SENTIENTSYSTEMS]AGENT_TURN 0" },
		{ name: "a line with its state prefix still on", line: "SentientSystemsCore_UI: [SENTIENTSYSTEMS] AGENT_TURN 0" },
	])("ignores $name", ({ line }) => {
		expect(parseLine(line)).toEqual({ result: "untagged" });
	});

	test.each([
		{ name: "the tag alone", line: "[SENTIENTSYSTEMS]", reason: "The line has no kind" },
		{ name: "the tag and a space", line: "[SENTIENTSYSTEMS] ", reason: "The line has no kind" },
		{ name: "an unknown kind", line: "[SENTIENTSYSTEMS] STATE_READY", reason: "STATE_READY is not a known kind" },
		{ name: "a turn with no player ID", line: "[SENTIENTSYSTEMS] AGENT_TURN", reason: "AGENT_TURN needs one player ID, and got \"\"" },
		{ name: "a turn with nil", line: "[SENTIENTSYSTEMS] AGENT_TURN nil", reason: "AGENT_TURN needs one player ID, and got \"nil\"" },
		{ name: "a negative player ID", line: "[SENTIENTSYSTEMS] AGENT_TURN -1", reason: "AGENT_TURN needs one player ID, and got \"-1\"" },
		{ name: "two player IDs", line: "[SENTIENTSYSTEMS] AGENT_TURN 0 1", reason: "AGENT_TURN needs one player ID, and got \"0 1\"" },
	])("reports $name as invalid", ({ line, reason }) => {
		expect(parseLine(line)).toEqual({ result: "invalid", reason });
	});
});
