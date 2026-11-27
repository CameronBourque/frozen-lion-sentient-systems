// The end turn action, which runs the call in
// Scripts/Actions/SentientSystemsCore_ActionsTurn.lua.

import { z } from "zod";
import { BLOCKERS } from "../schemas.js";
import type { TunerClient } from "../tuner/client.js";
import { ACTION_FAILURE, sendAction } from "./actions.js";

export const END_TURN_RESULT = z.discriminatedUnion("ok", [
	z.object({
		ok: z.literal(true),
		skipped: BLOCKERS.optional().describe(
			"With force, the blockers the game skipped, and the units that needed orders. The list leaves out the unit blockers, because the units stand in for them. Left out without force.",
		),
	}),
	ACTION_FAILURE,
]);

export type EndTurnResult = z.infer<typeof END_TURN_RESULT>;

// Ends the player's turn. Without force, it fails with the blockers and the
// units that need orders while any are left. With force, the game skips them,
// and the result lists them. It fails while a diplomacy session is open, even
// with force, and for a second call in one turn, because a second request can
// skip a turn.
export function endTurn(client: TunerClient, playerID: number, force = false): Promise<EndTurnResult> {
	return sendAction(client, `SentientSystems_EndTurn(${playerID}, ${force})`, END_TURN_RESULT);
}
