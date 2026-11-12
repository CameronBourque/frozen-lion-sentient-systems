// The deal actions, which run the calls in
// Scripts/Actions/SentientSystemsCore_ActionsDeals.lua.

import type { TunerClient } from "../tuner/client.js";
import { type ActionResult, sendAction } from "./actions.js";

// Accepts or rejects the deal that another player has put to the player, from
// the proposals in the state. An ok result means the game took the answer and
// the session closed.
export function respondToDeal(client: TunerClient, playerID: number, otherPlayerID: number, accept: boolean): Promise<ActionResult> {
	return sendAction(client, `SentientSystems_RespondToDeal(${playerID}, ${otherPlayerID}, ${accept})`);
}
