// What the bridge does each time it connects to the tuner: it calls the core mod for its version
// and logs it, then asks whose turn is active, so a restart in the middle of a turn doesn't miss
// the turn. A failure logs a warning and never throws, because a game load resets the socket and
// the next connect tries again. docs/design/core/bridge.md has the design.

import { readLine } from "./events.js";
import { warn } from "./log.js";
import { type TunerClient, TunerLuaError, TunerMissingStateError, TunerTimeoutError } from "./tuner/client.js";

// The core mod's UI state, where its functions for the bridge live.
export const CORE_STATE = "SentientSystemsCore_UI";

export async function onConnect(client: TunerClient): Promise<void> {
	try {
		await callCore(client, "SentientSystems_GetVersion()");
		// A failed version call skips this one, which would fail the same way.
		await callCore(client, "SentientSystems_Resync()");
	} catch (error) {
		warn(explainFailure(error));
	}
}

// Runs Lua in the core mod's state and reads each line it prints.
async function callCore(client: TunerClient, lua: string): Promise<void> {
	const { lines } = await client.run(CORE_STATE, lua);

	lines.forEach((line) => readLine(line));
}

// The warning for a failed call, with what the user can do about it.
function explainFailure(error: unknown): string {
	if (error instanceof TunerMissingStateError) {
		return `The core mod's state ${CORE_STATE} isn't loaded. Turn on Sentient Systems Core in Additional Content, then load a game. The bridge checks again when it reconnects`;
	}

	if (error instanceof TunerTimeoutError) {
		return "The game didn't answer the core mod check in time, maybe because a game is loading. The bridge checks again when it reconnects";
	}

	if (error instanceof TunerLuaError) {
		return `The core mod check failed in the game: ${error.message}`;
	}

	return `The core mod check failed: ${error instanceof Error ? error.message : String(error)}`;
}
