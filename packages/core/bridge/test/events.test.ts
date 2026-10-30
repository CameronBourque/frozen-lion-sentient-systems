// Tests for events.ts.

import { afterEach, describe, expect, test, vi } from "vitest";
import { describeEvent, KINDS, parseLine, readLine, stripState } from "../src/events.js";
import { Logger } from "../src/log.js";

afterEach(() => {
	vi.restoreAllMocks();
});

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
		expect(describeEvent({ type: "turn", playerId: 0 })).toEqual({ level: "info", event: "turn", msg: "Player 0's turn started", fields: { playerId: 0 } });
	});

	test("names the core version", () => {
		expect(describeEvent({ type: "version", version: "0.1.0" })).toEqual({ level: "info", event: "core_version", msg: "Core mod version is 0.1.0", fields: { version: "0.1.0" } });
	});

	test("names the state the core mod loaded in", () => {
		expect(describeEvent({ type: "loaded", context: "SentientSystemsCore_UI" })).toEqual({ level: "info", event: "core_loaded", msg: "Core mod loaded in the SentientSystemsCore_UI state", fields: { state: "SentientSystemsCore_UI" } });
	});

	test("says the game waits for the click", () => {
		expect(describeEvent({ type: "load_ready" })).toEqual({ level: "info", event: "load_ready", msg: "The game has loaded, and waits for the click on the loading screen's button", fields: {} });
	});

	test("names the turn a game is ready on", () => {
		expect(describeEvent({ type: "game_ready", turn: 1 })).toEqual({ level: "info", event: "game_ready", msg: "The game is ready on turn 1", fields: { turn: 1 } });
	});

	test("names the handler and the message of an error", () => {
		expect(describeEvent({ type: "error", handler: "OnPlayerTurnActivated", message: "boom" })).toEqual({
			level: "error",
			event: "core_error",
			msg: "Lua error in OnPlayerTurnActivated: boom",
			fields: { handler: "OnPlayerTurnActivated", message: "boom" },
		});
	});

	test("puts an error's traceback in the fields, not the message", () => {
		expect(describeEvent({ type: "error", handler: "OnPlayerTurnActivated", message: "boom", traceback: "\t[C]: in function 'error'" })).toEqual({
			level: "error",
			event: "core_error",
			msg: "Lua error in OnPlayerTurnActivated: boom",
			fields: { handler: "OnPlayerTurnActivated", message: "boom", traceback: "\t[C]: in function 'error'" },
		});
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

	test("reads a line for the loading screen's button", () => {
		expect(parseLine("[SENTIENTSYSTEMS] LOAD_READY")).toEqual({ result: "event", event: { type: "load_ready" } });
	});

	test("reads the turn of a game line", () => {
		expect(parseLine("[SENTIENTSYSTEMS] GAME_READY 152")).toEqual({ result: "event", event: { type: "game_ready", turn: 152 } });
	});

	test("reads an error's message with its spaces", () => {
		expect(parseLine("[SENTIENTSYSTEMS] ERROR OnPlayerTurnActivated attempt to index a nil value")).toEqual({
			result: "event",
			event: { type: "error", handler: "OnPlayerTurnActivated", message: "attempt to index a nil value" },
		});
	});

	test("keeps double spaces and tabs in an error's message", () => {
		expect(parseLine("[SENTIENTSYSTEMS] ERROR OnPlayerTurnActivated a  b\tc")).toMatchObject({ event: { message: "a  b\tc" } });
	});

	test("turns \\p in an error back into a percent sign", () => {
		expect(parseLine("[SENTIENTSYSTEMS] ERROR OnPlayerTurnActivated invalid option '\\ps' at 50\\p done, with a \\\\p backslash")).toMatchObject({
			event: { message: "invalid option '%s' at 50% done, with a \\p backslash" },
		});
	});

	test("turns the escapes in an error back into a newline and a backslash", () => {
		expect(parseLine("[SENTIENTSYSTEMS] ERROR OnPlayerTurnActivated line one\\nline two with a \\\\ backslash")).toMatchObject({
			event: { message: "line one\nline two with a \\ backslash" },
		});
	});

	test("leaves an unknown escape as it is", () => {
		expect(parseLine("[SENTIENTSYSTEMS] ERROR OnPlayerTurnActivated C:\\temp")).toMatchObject({ event: { message: "C:\\temp" } });
	});

	// A line that the core mod printed in a running game on 2026-10-23, with its trace cut short.
	test("splits the traceback off an error from the game", () => {
		const line = "SentientSystemsCore_UI: [SENTIENTSYSTEMS] ERROR ProbeNil [string \"(function()...\"]:5: attempt to index a nil value\\nstack traceback:\\n\t[string \"(function()...\"]:5: in function '(anonymous)'\\n\t[C]: in function 'pcall'";

		expect(parseLine(stripState(line))).toEqual({
			result: "event",
			event: {
				type: "error",
				handler: "ProbeNil",
				message: "[string \"(function()...\"]:5: attempt to index a nil value",
				traceback: "\t[string \"(function()...\"]:5: in function '(anonymous)'\n\t[C]: in function 'pcall'",
			},
		});
	});

	// A line from the game test on 2026-10-23, with its trace cut short. The core mod escaped each
	// backslash in the paths, so String.raw keeps them as the game printed them.
	test("cuts the paths in an error from the game down to the game's folder", () => {
		const path = String.raw`C:\\Users\\lion1\\OneDrive\\Documents\\My Games\\Sid Meier's Civilization VI\\Mods\\SentientSystemsCore\\UI\\SentientSystemsCore_UI.lua`;
		const line = String.raw`[SENTIENTSYSTEMS] ERROR OnPlayerTurnActivated ${path}:38: test\nstack traceback:\n${"\t"}[C]: in function 'error'\n${"\t"}${path}:38: in function 'OnPlayerTurnActivated'`;
		const short = String.raw`Sid Meier's Civilization VI\Mods\SentientSystemsCore\UI\SentientSystemsCore_UI.lua`;

		expect(parseLine(line)).toMatchObject({
			event: { message: `${short}:38: test`, traceback: `\t[C]: in function 'error'\n\t${short}:38: in function 'OnPlayerTurnActivated'` },
		});
	});

	test("cuts a path in the game's install folder", () => {
		const line = String.raw`[SENTIENTSYSTEMS] ERROR OnPlayerTurnActivated C:\\Program Files (x86)\\Steam\\steamapps\\common\\Sid Meier's Civilization VI\\Base\\Assets\\UI\\InGame.lua:12: boom`;

		expect(parseLine(line)).toMatchObject({ event: { message: String.raw`Sid Meier's Civilization VI\Base\Assets\UI\InGame.lua:12: boom` } });
	});

	test("cuts a path at the first game folder in it", () => {
		const line = String.raw`[SENTIENTSYSTEMS] ERROR OnPlayerTurnActivated D:\\Sid Meier's Civilization VI\\Sid Meier's Civilization VI\\x.lua:1: boom`;

		expect(parseLine(line)).toMatchObject({ event: { message: String.raw`Sid Meier's Civilization VI\Sid Meier's Civilization VI\x.lua:1: boom` } });
	});

	test("leaves a path outside the game's folder as it is", () => {
		const line = String.raw`[SENTIENTSYSTEMS] ERROR OnPlayerTurnActivated C:\\Users\\me\\x.lua:1: boom`;

		expect(parseLine(line)).toMatchObject({ event: { message: String.raw`C:\Users\me\x.lua:1: boom` } });
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
		{ name: "a button line with an argument", line: "[SENTIENTSYSTEMS] LOAD_READY 1", reason: "LOAD_READY takes nothing after it, and got \"1\"" },
		{ name: "a game line with no turn", line: "[SENTIENTSYSTEMS] GAME_READY", reason: "GAME_READY needs one turn, and got \"\"" },
		{ name: "a game line with nil", line: "[SENTIENTSYSTEMS] GAME_READY nil", reason: "GAME_READY needs one turn, and got \"nil\"" },
		{ name: "a negative turn", line: "[SENTIENTSYSTEMS] GAME_READY -1", reason: "GAME_READY needs one turn, and got \"-1\"" },
		{ name: "two turns", line: "[SENTIENTSYSTEMS] GAME_READY 1 2", reason: "GAME_READY needs one turn, and got \"1 2\"" },
		{ name: "an error with no handler", line: "[SENTIENTSYSTEMS] ERROR", reason: "ERROR needs a handler name and a message, and got \"\"" },
		{ name: "an error with no message", line: "[SENTIENTSYSTEMS] ERROR OnPlayerTurnActivated", reason: "ERROR needs a handler name and a message, and got \"OnPlayerTurnActivated\"" },
		{ name: "an error with a bad handler name", line: "[SENTIENTSYSTEMS] ERROR On.Turn boom", reason: "ERROR needs a handler name and a message, and got \"On.Turn boom\"" },
	])("reports $name as invalid", ({ line, reason }) => {
		expect(parseLine(line)).toEqual({ result: "invalid", reason });
	});
});

describe("readLine", () => {
	const logger = new Logger("debug");

	test("logs and returns the event in a line with its state prefix", () => {
		const print = vi.spyOn(console, "log").mockImplementation(() => {});

		expect(readLine("SentientSystemsCore_UI: [SENTIENTSYSTEMS] AGENT_TURN 0", logger)).toEqual({ type: "turn", playerId: 0 });
		expect(print).toHaveBeenCalledWith(expect.stringMatching(/ {2}Player 0's turn started$/));
	});

	test("logs an error line as an error, on stderr", () => {
		const logged = vi.spyOn(console, "log").mockImplementation(() => {});
		const print = vi.spyOn(console, "error").mockImplementation(() => {});

		expect(readLine("SentientSystemsCore_UI: [SENTIENTSYSTEMS] ERROR OnPlayerTurnActivated boom", logger)).toEqual({ type: "error", handler: "OnPlayerTurnActivated", message: "boom" });
		expect(print).toHaveBeenCalledWith(expect.stringMatching(/ {2}error: Lua error in OnPlayerTurnActivated: boom$/));
		expect(logged).not.toHaveBeenCalled();
	});

	test("reads a command's line, which has no prefix", () => {
		vi.spyOn(console, "log").mockImplementation(() => {});

		expect(readLine("[SENTIENTSYSTEMS] CORE_VERSION 0.1.0", logger)).toEqual({ type: "version", version: "0.1.0" });
	});

	test("hands the event to onEvent before it logs the event", () => {
		const order: string[] = [];

		vi.spyOn(console, "log").mockImplementation(() => order.push("logged"));
		readLine("[SENTIENTSYSTEMS] LOAD_READY", logger, (event) => order.push(event.type));

		expect(order).toEqual(["load_ready", "logged"]);
	});

	test("doesn't call onEvent for a line with no event", () => {
		const onEvent = vi.fn();

		vi.spyOn(console, "warn").mockImplementation(() => {});
		readLine("InGame: Loading InGame UI", logger, onEvent);
		readLine("[SENTIENTSYSTEMS] GAME_READY nil", logger, onEvent);

		expect(onEvent).not.toHaveBeenCalled();
	});

	test("warns about a tagged line that doesn't parse, with the whole line", () => {
		const print = vi.spyOn(console, "warn").mockImplementation(() => {});

		expect(readLine("SentientSystemsCore_UI: [SENTIENTSYSTEMS] AGENT_TURN nil", logger)).toBeUndefined();
		expect(print).toHaveBeenCalledWith(expect.stringMatching(/warning: AGENT_TURN needs one player ID, and got "nil": SentientSystemsCore_UI: \[SENTIENTSYSTEMS\] AGENT_TURN nil$/));
	});

	test("ignores an untagged line", () => {
		const logged = vi.spyOn(console, "log").mockImplementation(() => {});
		const warned = vi.spyOn(console, "warn").mockImplementation(() => {});

		expect(readLine("InGame: Loading InGame UI", logger)).toBeUndefined();
		expect(logged).not.toHaveBeenCalled();
		expect(warned).not.toHaveBeenCalled();
	});
});
