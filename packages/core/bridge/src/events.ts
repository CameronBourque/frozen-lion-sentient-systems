// Turns the core mod's tagged lines into typed events. A tagged line is "[SENTIENTSYSTEMS] <KIND>
// <args>", joined with spaces, such as "[SENTIENTSYSTEMS] AGENT_TURN 0". docs/design/core/in-game-lua.md
// has the format.

import { log, warn } from "./log.js";

export const TAG = "[SENTIENTSYSTEMS]";

export type CoreEvent =
	| { type: "turn"; playerId: number }
	| { type: "version"; version: string }
	| { type: "loaded"; context: string };

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
];

// The name and colon the tuner puts before a state's prints, such as "SentientSystemsCore_UI: ".
const STATE_PREFIX = /^\w+: /;

// Removes the state prefix from a line of the client's output events. Main State's prints have no
// prefix, and neither do the later lines of a print with a newline, so those come back unchanged.
export function stripState(line: string): string {
	return line.replace(STATE_PREFIX, "");
}

// The text the bridge logs for an event, such as "turn 0".
export function describeEvent(event: CoreEvent): string {
	switch (event.type) {
		case "turn":
			return `turn ${event.playerId}`;
		case "version":
			return `core version ${event.version}`;
		case "loaded":
			return `core loaded in ${event.context}`;
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
export function readLine(line: string): CoreEvent | undefined {
	const parsed = parseLine(stripState(line));

	if (parsed.result === "event") {
		log(describeEvent(parsed.event));

		return parsed.event;
	}

	if (parsed.result === "invalid") {
		warn(`${parsed.reason}: ${line}`);
	}

	return undefined;
}
