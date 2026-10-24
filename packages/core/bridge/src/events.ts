// Turns the core mod's tagged lines into typed events. A tagged line is "[SENTIENTSYSTEMS] <KIND>
// <args>", joined with spaces, such as "[SENTIENTSYSTEMS] AGENT_TURN 0". docs/design/core/in-game-lua.md
// has the format.

import type { LogFields, Logger, LogLevel } from "./log.js";

export const TAG = "[SENTIENTSYSTEMS]";

export type CoreEvent =
	| { type: "turn"; playerId: number }
	| { type: "version"; version: string }
	| { type: "loaded"; context: string }
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
// A release version such as "0.1.0", with an optional suffix such as "-beta.1". A mod with no
// version prints "nil".
const VERSION = /^\d+\.\d+\.\d+(-[\w.]+)?$/;
// A Lua state's name, from ContextPtr:GetID(), such as "SentientSystemsCore_UI".
const CONTEXT = /^\w+$/;
// An event handler's name, such as "OnPlayerTurnActivated".
const HANDLER = /^\w+$/;
// The escapes SentientSystems_CatchErrors writes, so an error with newlines fits on one line: "\\"
// for a backslash and "\n" for a newline.
const ESCAPE = /\\([\\n])/g;
// The line the game's Lua puts between an error and its stack trace.
const TRACEBACK = "\nstack traceback:\n";

// Reads "ERROR <handler> <message>". The message is the rest of the line, spaces and tabs included.
function parseError(args: string[]): CoreEvent | string {
	const [handler = "", ...words] = args;
	const text = words.join(" ").replace(ESCAPE, (_escape, character: string) => character === "n" ? "\n" : "\\");

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
export function readLine(line: string, logger: Logger): CoreEvent | undefined {
	const parsed = parseLine(stripState(line));

	if (parsed.result === "event") {
		const { level, event, msg, fields } = describeEvent(parsed.event);

		logger.log(level, event, msg, fields);

		return parsed.event;
	}

	if (parsed.result === "invalid") {
		logger.warn("bad_line", `${parsed.reason}: ${line}`, { reason: parsed.reason, line });
	}

	return undefined;
}
