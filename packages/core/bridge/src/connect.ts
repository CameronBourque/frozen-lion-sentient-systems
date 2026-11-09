// On each connect to the tuner, logs the core mod's version and asks whose turn
// is active. A failure warns and never throws: a game load resets the socket,
// and the next connect tries again. docs/design/core/bridge.md has the design.

import { explainFailure } from "./errors.js";
import { readLine } from "./events.js";
import type { Logger } from "./log.js";
import type { TunerClient } from "./tuner/client.js";

// The core mod's UI state, where its functions for the bridge live.
export const CORE_STATE = "SentientSystemsCore_UI";

export async function onConnect(client: TunerClient, logger: Logger): Promise<void> {
	try {
		await callCore(client, logger, "SentientSystems_GetVersion()");
		// A failed version call skips this one, which would fail the same way.
		await callCore(client, logger, "SentientSystems_Resync()");
	} catch (error) {
		logger.warn("core_check_failed", explainFailure(error, "core mod check", ". The bridge checks again when it reconnects"));
	}
}

// Runs Lua in the core mod's state and reads each line it prints.
async function callCore(client: TunerClient, logger: Logger, lua: string): Promise<void> {
	const { lines } = await client.run(CORE_STATE, lua);

	lines.forEach((line) => readLine(line, logger));
}
