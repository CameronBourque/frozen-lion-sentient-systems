// Reads JSON that the core mod builds and keeps in pieces, such as the state and the choices. The
// tuner gives no reply to a command whose output passes about 2 MiB, so the core mod's
// SentientSystems_Stash keeps the JSON in pieces, and the bridge reads one piece per command and
// joins them. docs/design/core/in-game-lua.md describes the stash.

import type { z } from "zod";
import { CORE_STATE } from "./connect.js";
import { type TunerClient, TunerLuaError, TunerMissingStateError, TunerTimeoutError } from "./tuner/client.js";

export type StashResult<T> =
	| { ok: true; value: T; bytes: number }
	| { ok: false; error: string };

// Runs the Lua call that builds the JSON, such as SentientSystems_GetState(0), reads the JSON through
// the stash, and checks it against the schema. what names the JSON in errors, such as "state". Every
// failure, from the tuner, the game, the JSON, or the schema, comes back as an error that says what
// went wrong, instead of an exception.
export async function readStash<T>(client: TunerClient, call: string, schema: z.ZodType<T>, what: string): Promise<StashResult<T>> {
	let json: string;

	try {
		json = await readPieces(client, call);
	} catch (error) {
		return { ok: false, error: explainFailure(error, what) };
	}

	let value: unknown;

	try {
		value = JSON.parse(json);
	} catch (error) {
		return { ok: false, error: `The core mod's ${what} JSON isn't valid: ${(error as Error).message}` };
	}

	const parsed = schema.safeParse(value);

	if (!parsed.success) {
		return { ok: false, error: `The core mod's ${what} JSON doesn't match the schema: ${parsed.error.issues.map((issue) => describeIssue(issue, what)).join("; ")}` };
	}

	return { ok: true, value: parsed.data, bytes: Buffer.byteLength(json) };
}

// Asks the core mod to build and keep the JSON, then reads each piece with its own command and
// joins them. The core mod escapes each newline in the JSON, so the pieces join with nothing between.
async function readPieces(client: TunerClient, call: string): Promise<string> {
	const { lines } = await client.run(CORE_STATE, `SentientSystems_Stash(${call})`);
	const count = Number(lines.at(-1));

	if (lines.length !== 1 || !Number.isInteger(count) || count < 1) {
		throw new Error(`SentientSystems_Stash printed ${JSON.stringify(lines)}, not a piece count`);
	}

	const pieces: string[] = [];

	for (let piece = 1; piece <= count; piece++) {
		const result = await client.run(CORE_STATE, `SentientSystems_PrintPiece(${piece})`);

		pieces.push(result.lines.join(""));
	}

	return pieces.join("");
}

// The text for one schema issue, with the field's path in front, such as "cities.0.name: Invalid input".
function describeIssue(issue: z.core.$ZodIssue, what: string): string {
	return `${issue.path.join(".") || `the ${what}`}: ${issue.message}`;
}

// The error for a failed read, with what the user can do about it.
function explainFailure(error: unknown, what: string): string {
	if (error instanceof TunerMissingStateError) {
		return `The core mod's state ${CORE_STATE} isn't loaded. Turn on Sentient Systems Core in Additional Content, then load a game`;
	}

	if (error instanceof TunerTimeoutError) {
		return `The game didn't answer the ${what} request in time, maybe because a game is loading`;
	}

	if (error instanceof TunerLuaError) {
		return `The core mod failed to build the ${what}: ${error.message.split("\n")[0]}`;
	}

	return `Reading the ${what} failed: ${error instanceof Error ? error.message : String(error)}`;
}
