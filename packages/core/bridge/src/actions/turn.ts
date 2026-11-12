// The end turn action, which runs the call in
// Scripts/Actions/SentientSystemsCore_ActionsTurn.lua.

import type { TunerClient } from "../tuner/client.js";
import { type ActionResult, sendAction } from "./actions.js";

// Ends the player's turn. Without force, it fails with the blockers and the
// units that need orders while any are left. With force, the game skips them.
// It fails for a second call in one turn, because a second request can skip a
// turn.
export function endTurn(client: TunerClient, playerID: number, force = false): Promise<ActionResult> {
	return sendAction(client, `SentientSystems_EndTurn(${playerID}, ${force})`);
}
