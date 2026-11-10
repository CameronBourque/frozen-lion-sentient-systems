// The pantheon and religion actions, which run the calls in
// Scripts/Actions/SentientSystemsCore_ActionsReligion.lua.

import type { TunerClient } from "../tuner/client.js";
import { type ActionResult, sendAction } from "./actions.js";

// Founds the player's pantheon with a belief from the pantheon choice, such as
// BELIEF_RELIGIOUS_SETTLEMENTS. An ok result means the game took the request.
export function foundPantheon(client: TunerClient, playerID: number, belief: string): Promise<ActionResult> {
	return sendAction(client, `SentientSystems_FoundPantheon(${playerID}, ${JSON.stringify(belief)})`);
}
