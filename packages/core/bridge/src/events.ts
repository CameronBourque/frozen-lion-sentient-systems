// Turns the core mod's tagged lines into typed events. A tagged line is "[SENTIENTSYSTEMS] <KIND>
// <args>", joined with spaces, such as "[SENTIENTSYSTEMS] AGENT_TURN 0". docs/design/core/in-game-lua.md
// has the format.

import type { LogFields, Logger, LogLevel } from "./log.js";

export const TAG = "[SENTIENTSYSTEMS]";

export type CoreEvent =
	| { type: "turn"; playerId: number }
	| { type: "version"; version: string }
	| { type: "loaded"; context: string }
	// The loading screen shows its button. Commands don't run until the click.
	| { type: "load_ready" }
	// The loading screen's button was clicked, by the player or the game, so commands run from now on.
	| { type: "game_ready"; turn: number }
	// A Lua error that SentientSystems_CatchErrors caught in a core mod event handler.
	| { type: "error"; handler: string; message: string; traceback?: string };

// "untagged" is a line from the game or another mod. "invalid" is a tagged line the bridge can't
// read, such as a kind from a newer core mod, with the reason.
export type ParseResult =
	| { result: "event"; event: CoreEvent }
	| { result: "untagged" }
	| { result: "invalid"; reason: string };

interface Kind {
	name: string;
	example: string;
	// Returns the event, or the reason the arguments are wrong.
	parse: (args: string[]) => CoreEvent | string;
}

const PLAYER_ID = /^\d+$/;
// A game turn, from Game.GetCurrentGameTurn().
const TURN = /^\d+$/;
// A release version such as "0.1.0", with an optional suffix such as "-beta.1". A mod with no
// version prints "nil".
const VERSION = /^\d+\.\d+\.\d+(-[\w.]+)?$/;
// A Lua state's name, from ContextPtr:GetID(), such as "SentientSystemsCore_UI".
const CONTEXT = /^\w+$/;
// An event handler's name, such as "OnPlayerTurnActivated".
const HANDLER = /^\w+$/;
// The escapes SentientSystems_CatchErrors writes, so an error with newlines fits on one line: "\\"
// for a backslash, "\n" for a newline, and "\p" for a percent sign, which the game's log would read
// as a printf format code.
const ESCAPE = /\\([\\np])/g;
const ESCAPED = { n: "\n", p: "%", "\\": "\\" } as const;
// The line the game's Lua puts between an error and its stack trace.
const TRACEBACK = "\nstack traceback:\n";
// The game's folder, in both the My Games folder and the install folder. A Lua error's paths are cut
// to start here, so they're shorter and don't hold the user's name.
// The name has no regex special characters, so the pattern below uses it as it is.
const GAME_NAME = "Sid Meier's Civilization VI";
const GAME_FOLDER = `${GAME_NAME}\\`;
// A path from its drive to the game's folder, such as
// "C:\Users\me\Documents\My Games\Sid Meier's Civilization VI\". Each folder is one name and a
// backslash, so the lazy match stops at the first game folder.
const DRIVE = String.raw`[A-Za-z]:\\`;
const FOLDER = String.raw`[^\\\n]*\\`;
const GAME_PATH = new RegExp(String.raw`${DRIVE}(?:${FOLDER})*?${GAME_NAME}\\`, "g");

// Reads "ERROR <handler> <message>". The message is the rest of the line, spaces and tabs included.
function parseError(args: string[]): CoreEvent | string {
	const [handler = "", ...words] = args;
	const text = words.join(" ")
		.replace(ESCAPE, (_escape, character: keyof typeof ESCAPED) => ESCAPED[character])
		.replace(GAME_PATH, GAME_FOLDER);

	if (!HANDLER.test(handler) || text === "") {
		return `ERROR needs a handler name and a message, and got "${args.join(" ")}"`;
	}

	const split = text.indexOf(TRACEBACK);

	return split === -1
		? { type: "error", handler, message: text }
		: { type: "error", handler, message: text.slice(0, split), traceback: text.slice(split + TRACEBACK.length) };
}

export const KINDS: Kind[] = [
	{
		name: "AGENT_TURN",
		example: "[SENTIENTSYSTEMS] AGENT_TURN 0",
		parse: (args) => args.length === 1 && PLAYER_ID.test(args[0])
			? { type: "turn", playerId: Number(args[0]) }
			: `AGENT_TURN needs one player ID, and got "${args.join(" ")}"`,
	},
	{
		name: "CORE_VERSION",
		example: "[SENTIENTSYSTEMS] CORE_VERSION 0.1.0",
		parse: (args) => args.length === 1 && VERSION.test(args[0])
			? { type: "version", version: args[0] }
			: `CORE_VERSION needs one version, and got "${args.join(" ")}"`,
	},
	{
		name: "CORE_LOADED",
		example: "[SENTIENTSYSTEMS] CORE_LOADED SentientSystemsCore_UI",
		parse: (args) => args.length === 1 && CONTEXT.test(args[0])
			? { type: "loaded", context: args[0] }
			: `CORE_LOADED needs one state name, and got "${args.join(" ")}"`,
	},
	{
		name: "LOAD_READY",
		example: "[SENTIENTSYSTEMS] LOAD_READY",
		parse: (args) => args.length === 0
			? { type: "load_ready" }
			: `LOAD_READY takes nothing after it, and got "${args.join(" ")}"`,
	},
	{
		name: "GAME_READY",
		example: "[SENTIENTSYSTEMS] GAME_READY 1",
		parse: (args) => args.length === 1 && TURN.test(args[0])
			? { type: "game_ready", turn: Number(args[0]) }
			: `GAME_READY needs one turn, and got "${args.join(" ")}"`,
	},
	{
		name: "ERROR",
		example: "[SENTIENTSYSTEMS] ERROR OnPlayerTurnActivated attempt to index a nil value",
		parse: parseError,
	},
];

// The name and colon the tuner puts before a state's prints, such as "SentientSystemsCore_UI: ".
const STATE_PREFIX = /^\w+: /;

// Removes the state prefix from a line of the client's output events. Main State's prints have no
// prefix, and neither do the later lines of a print with a newline, so those come back unchanged.
export function stripState(line: string): string {
	return line.replace(STATE_PREFIX, "");
}

// What the bridge logs for an event: its level, its event name, a message, and its fields.
export interface EventLog {
	level: LogLevel;
	event: string;
	msg: string;
	fields: LogFields;
}

export function describeEvent(event: CoreEvent): EventLog {
	switch (event.type) {
		case "turn":
			return { level: "info", event: "turn", msg: `Player ${event.playerId}'s turn started`, fields: { playerId: event.playerId } };
		case "version":
			return { level: "info", event: "core_version", msg: `Core mod version is ${event.version}`, fields: { version: event.version } };
		case "loaded":
			return { level: "info", event: "core_loaded", msg: `Core mod loaded in the ${event.context} state`, fields: { state: event.context } };
		case "load_ready":
			return { level: "info", event: "load_ready", msg: "The game has loaded, and waits for the click on the loading screen's button", fields: {} };
		case "game_ready":
			return { level: "info", event: "game_ready", msg: `The game is ready on turn ${event.turn}`, fields: { turn: event.turn } };
		case "error":
			return {
				level: "error",
				event: "core_error",
				msg: `Lua error in ${event.handler}: ${event.message}`,
				// A missing traceback stays out of the record.
				fields: { handler: event.handler, message: event.message, ...(event.traceback === undefined ? {} : { traceback: event.traceback }) },
			};
	}
}

// Parses a line with no state prefix.
export function parseLine(line: string): ParseResult {
	if (line !== TAG && !line.startsWith(`${TAG} `)) {
		return { result: "untagged" };
	}

	const [name = "", ...args] = line.slice(TAG.length + 1).split(" ");
	const kind = KINDS.find((candidate) => candidate.name === name);

	if (!kind) {
		return { result: "invalid", reason: name === "" ? "The line has no kind" : `${name} is not a known kind` };
	}

	const parsed = kind.parse(args);

	return typeof parsed === "string" ? { result: "invalid", reason: parsed } : { result: "event", event: parsed };
}

// Reads one line from the game, from an output event or from a command's result. Logs the event
// and returns it, warns about a tagged line that doesn't parse, and ignores an untagged line.
// onEvent runs before the event is logged, so a handler that starts a new log file puts the
// event's own line in the new file.
export function readLine(line: string, logger: Logger, onEvent?: (event: CoreEvent) => void): CoreEvent | undefined {
	const parsed = parseLine(stripState(line));

	if (parsed.result === "event") {
		onEvent?.(parsed.event);

		const { level, event, msg, fields } = describeEvent(parsed.event);

		logger.log(level, event, msg, fields);

		return parsed.event;
	}

	if (parsed.result === "invalid") {
		logger.warn("bad_line", `${parsed.reason}: ${line}`, { reason: parsed.reason, line });
	}

	return undefined;
}
