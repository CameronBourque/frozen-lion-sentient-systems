// Waits while the game doesn't answer, such as during a load, so a turn spends
// no model calls on tool calls that can only time out.
// docs/design/agents/game-load.md has the design.

import { setTimeout as sleep } from "node:timers/promises";
import { CORE_STATE } from "../connect.js";
import type { Logger } from "../log.js";
import { type TunerClient, TunerLuaError } from "../tuner/client.js";

export const GAME_WAIT_MS = 2000;

// A Lua error is still an answer. A missing core state means a load is under
// way, so the game isn't ready yet.
async function gameAnswers(client: TunerClient): Promise<boolean> {
	try {
		await client.run(CORE_STATE, "return");

		return true;
	} catch (error) {
		return error instanceof TunerLuaError;
	}
}

// Returns true once the game answers, and false when the signal aborts first.
export async function waitForGame(client: TunerClient, logger: Logger, playerID: number, signal: AbortSignal | undefined, waitMs = GAME_WAIT_MS): Promise<boolean> {
	if (await gameAnswers(client)) {
		return true;
	}

	logger.info("game_silent", `The game doesn't answer, so player ${playerID}'s turn waits for it`, { player: playerID });

	for (;;) {
		try {
			await sleep(waitMs, undefined, { signal });
		} catch {
			return false;
		}

		if (await gameAnswers(client)) {
			logger.info("game_answers", `The game answers again, so player ${playerID}'s turn goes on`, { player: playerID });

			return true;
		}
	}
}
