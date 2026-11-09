// The city actions, which run the calls in
// Scripts/Actions/SentientSystemsCore_ActionsCities.lua.

import type { Position } from "../schemas.js";
import type { TunerClient } from "../tuner/client.js";
import { type ActionResult, sendAction } from "./actions.js";

// Sends the core mod's production call for the item, with the tile of a
// district or a wonder, and append to add it to the end of the queue.
function sendProduction(client: TunerClient, playerID: number, cityID: number, item: string, tile: Position | undefined, append: boolean): Promise<ActionResult> {
	const args: (number | string)[] = [playerID, cityID, JSON.stringify(item)];

	if (tile !== undefined || append) {
		args.push(tile?.x ?? "nil", tile?.y ?? "nil");
	}

	if (append) {
		args.push("true");
	}

	return sendAction(client, `SentientSystems_SetProduction(${args.join(", ")})`);
}

// Replaces what a city is producing with the item, the type of an option of
// the production choice, such as UNIT_WARRIOR. A district or a wonder also
// takes the tile from the placement call. An ok result means the game took the
// order.
export function setProduction(client: TunerClient, playerID: number, cityID: number, item: string, tile?: Position): Promise<ActionResult> {
	return sendProduction(client, playerID, cityID, item, tile, false);
}

// Adds the item to the end of a city's production queue, as setProduction
// takes it.
export function queueProduction(client: TunerClient, playerID: number, cityID: number, item: string, tile?: Position): Promise<ActionResult> {
	return sendProduction(client, playerID, cityID, item, tile, true);
}

// Buys a unit or a building in a city. The item is the type of an option of the
// purchases choice, such as UNIT_BUILDER, and the yield is the key it is listed
// under. An ok result means the game took the order.
export function purchase(client: TunerClient, playerID: number, cityID: number, item: string, yieldKey: "gold" | "faith"): Promise<ActionResult> {
	return sendAction(client, `SentientSystems_Purchase(${playerID}, ${cityID}, ${JSON.stringify(item)}, ${JSON.stringify(yieldKey)})`);
}

// Buys a tile for a city with gold. The tile is one of the tiles of the
// purchases choice. An ok result means the game took the order.
export function purchaseTile(client: TunerClient, playerID: number, cityID: number, position: Position): Promise<ActionResult> {
	return sendAction(client, `SentientSystems_PurchaseTile(${playerID}, ${cityID}, ${position.x}, ${position.y})`);
}

// Orders a city to shoot at a tile in its range. An ok result means the game
// took the order, not that the shot has landed.
export function cityAttack(client: TunerClient, playerID: number, cityID: number, position: Position): Promise<ActionResult> {
	return sendAction(client, `SentientSystems_CityAttack(${playerID}, ${cityID}, ${position.x}, ${position.y})`);
}
