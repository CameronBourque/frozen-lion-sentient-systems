// The city actions, which run the calls in
// Scripts/Actions/SentientSystemsCore_ActionsCities.lua.

import type { TunerClient } from "../tuner/client.js";
import { type ActionResult, sendAction } from "./actions.js";

// Orders a city to shoot at a tile in its range. An ok result means the game
// took the order, not that the shot has landed.
export function cityAttack(client: TunerClient, playerID: number, cityID: number, x: number, y: number): Promise<ActionResult> {
	return sendAction(client, `SentientSystems_CityAttack(${playerID}, ${cityID}, ${x}, ${y})`);
}
