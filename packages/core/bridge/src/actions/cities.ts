// The city actions, which run the calls in
// Scripts/Actions/SentientSystemsCore_ActionsCities.lua.

import type { TunerClient } from "../tuner/client.js";
import { type ActionResult, sendAction } from "./actions.js";

// Replaces what a city is producing. The item is the type of an option of the
// production choice, such as UNIT_WARRIOR. A district or a wonder also takes
// the tile, x and y, from the placement call. An ok result means the game took
// the order.
export function setProduction(client: TunerClient, playerID: number, cityID: number, item: string, tile?: { x: number; y: number }): Promise<ActionResult> {
	const place = tile === undefined ? "" : `, ${tile.x}, ${tile.y}`;

	return sendAction(client, `SentientSystems_SetProduction(${playerID}, ${cityID}, ${JSON.stringify(item)}${place})`);
}

// Buys a unit or a building in a city. The item is the type of an option of the
// purchases choice, such as UNIT_BUILDER, and the yield is the key it is listed
// under. An ok result means the game took the order.
export function purchase(client: TunerClient, playerID: number, cityID: number, item: string, yieldKey: "gold" | "faith"): Promise<ActionResult> {
	return sendAction(client, `SentientSystems_Purchase(${playerID}, ${cityID}, ${JSON.stringify(item)}, ${JSON.stringify(yieldKey)})`);
}

// Orders a city to shoot at a tile in its range. An ok result means the game
// took the order, not that the shot has landed.
export function cityAttack(client: TunerClient, playerID: number, cityID: number, x: number, y: number): Promise<ActionResult> {
	return sendAction(client, `SentientSystems_CityAttack(${playerID}, ${cityID}, ${x}, ${y})`);
}
