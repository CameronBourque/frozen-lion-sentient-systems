// The envoy action, which runs the call in
// Scripts/Actions/SentientSystemsCore_ActionsEnvoys.lua.

import type { TunerClient } from "../tuner/client.js";
import { type ActionResult, sendAction } from "./actions.js";

// Sends envoys to a city-state, an ID from the envoys choice. The count is 1
// when left out. An ok result means the game took the requests.
export function sendEnvoys(client: TunerClient, playerID: number, cityState: number, count = 1): Promise<ActionResult> {
	return sendAction(client, `SentientSystems_SendEnvoys(${playerID}, ${cityState}, ${count})`);
}
