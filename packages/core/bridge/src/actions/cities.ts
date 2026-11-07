// The city actions, which run the calls in
// Scripts/Actions/SentientSystemsCore_ActionsCities.lua.

import type { TunerClient } from "../tuner/client.js";
import { type ActionResult, sendAction } from "./actions.js";

// Replaces what a city is producing. The item is the type of an option of the
// production choice, such as UNIT_WARRIOR. An ok result means the game took
// the order.
export function setProduction(client: TunerClient, playerID: number, cityID: number, item: string): Promise<ActionResult> {
	return sendAction(client, `SentientSystems_SetProduction(${playerID}, ${cityID}, ${JSON.stringify(item)})`);
}

// Orders a city to shoot at a tile in its range. An ok result means the game
// took the order, not that the shot has landed.
export function cityAttack(client: TunerClient, playerID: number, cityID: number, x: number, y: number): Promise<ActionResult> {
	return sendAction(client, `SentientSystems_CityAttack(${playerID}, ${cityID}, ${x}, ${y})`);
}
