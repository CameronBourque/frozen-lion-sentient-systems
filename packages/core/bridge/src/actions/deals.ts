// The deal and war actions, which run the calls in
// Scripts/Actions/SentientSystemsCore_ActionsDeals.lua.

import type { TunerClient } from "../tuner/client.js";
import { type ActionResult, sendAction } from "./actions.js";

// Accepts or rejects the deal that another player has put to the player, from
// the proposals in the state. An ok result means the game took the answer and
// the session closed.
export function respondToDeal(client: TunerClient, playerID: number, otherPlayerID: number, accept: boolean): Promise<ActionResult> {
	return sendAction(client, `SentientSystems_RespondToDeal(${playerID}, ${otherPlayerID}, ${accept})`);
}

// Declares a surprise war on the other player, a major civ or a city-state. It
// fails for a player not met or already at war, and with the game's reasons
// when the game doesn't allow the war.
export function declareWar(client: TunerClient, playerID: number, otherPlayerID: number): Promise<ActionResult> {
	return sendAction(client, `SentientSystems_DeclareWar(${playerID}, ${otherPlayerID})`);
}
