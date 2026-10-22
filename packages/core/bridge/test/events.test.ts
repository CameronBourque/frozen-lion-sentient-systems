// Tests for events.ts.

import { describe, expect, test } from "vitest";
import { describeEvent, KINDS, parseLine, stripState } from "../src/events.js";

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

describe("describeEvent", () => {
	test("names a turn by its player ID", () => {
		expect(describeEvent({ type: "turn", playerId: 0 })).toBe("turn 0");
	});

	test("names the core version", () => {
		expect(describeEvent({ type: "version", version: "0.1.0" })).toBe("core version 0.1.0");
	});

	test("names the state the core mod loaded in", () => {
		expect(describeEvent({ type: "loaded", context: "SentientSystemsCore_UI" })).toBe("core loaded in SentientSystemsCore_UI");
	});
});

describe("parseLine", () => {
	test.each(KINDS)("parses the $name example", ({ example }) => {
		expect(parseLine(example).result).toBe("event");
	});

	test("reads the player ID of a turn line", () => {
		expect(parseLine("[SENTIENTSYSTEMS] AGENT_TURN 12")).toEqual({ result: "event", event: { type: "turn", playerId: 12 } });
	});

	test.each(["0.1.0", "12.0.3", "1.0.0-beta.1"])("reads the version %s", (version) => {
		expect(parseLine(`[SENTIENTSYSTEMS] CORE_VERSION ${version}`)).toEqual({ result: "event", event: { type: "version", version } });
	});

	test("reads the state name of a load line", () => {
		expect(parseLine("[SENTIENTSYSTEMS] CORE_LOADED SentientSystemsCore_UI")).toEqual({ result: "event", event: { type: "loaded", context: "SentientSystemsCore_UI" } });
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
		{ name: "a missing version", line: "[SENTIENTSYSTEMS] CORE_VERSION nil", reason: "CORE_VERSION needs one version, and got \"nil\"" },
		{ name: "a version with two parts", line: "[SENTIENTSYSTEMS] CORE_VERSION 0.1", reason: "CORE_VERSION needs one version, and got \"0.1\"" },
		{ name: "two versions", line: "[SENTIENTSYSTEMS] CORE_VERSION 0.1.0 0.2.0", reason: "CORE_VERSION needs one version, and got \"0.1.0 0.2.0\"" },
		{ name: "a load line with no state name", line: "[SENTIENTSYSTEMS] CORE_LOADED", reason: "CORE_LOADED needs one state name, and got \"\"" },
		{ name: "a state name with a colon", line: "[SENTIENTSYSTEMS] CORE_LOADED InGame:", reason: "CORE_LOADED needs one state name, and got \"InGame:\"" },
		{ name: "two state names", line: "[SENTIENTSYSTEMS] CORE_LOADED InGame PlotInfo", reason: "CORE_LOADED needs one state name, and got \"InGame PlotInfo\"" },
	])("reports $name as invalid", ({ line, reason }) => {
		expect(parseLine(line)).toEqual({ result: "invalid", reason });
	});
});
