// The city actions, which run the calls in
// Scripts/Actions/SentientSystemsCore_ActionsCities.lua.

import type { TunerClient } from "../tuner/client.js";
import { type ActionResult, sendAction } from "./actions.js";

// Replaces what a city is producing, or adds the item to the end of its
// queue with append. The item is the type of an option of the production
// choice, such as UNIT_WARRIOR. A district or a wonder also takes the tile, x
// and y, from the placement call. An ok result means the game took the order.
export function setProduction(
	client: TunerClient,
	playerID: number,
	cityID: number,
	item: string,
	options: { tile?: { x: number; y: number }; append?: boolean } = {},
): Promise<ActionResult> {
	const { tile, append } = options;
	const args: (number | string)[] = [playerID, cityID, JSON.stringify(item)];

	if (tile !== undefined || append === true) {
		args.push(tile?.x ?? "nil", tile?.y ?? "nil");
	}

	if (append === true) {
		args.push("true");
	}

	return sendAction(client, `SentientSystems_SetProduction(${args.join(", ")})`);
}

// Buys a unit or a building in a city. The item is the type of an option of the
// purchases choice, such as UNIT_BUILDER, and the yield is the key it is listed
// under. An ok result means the game took the order.
export function purchase(client: TunerClient, playerID: number, cityID: number, item: string, yieldKey: "gold" | "faith"): Promise<ActionResult> {
	return sendAction(client, `SentientSystems_Purchase(${playerID}, ${cityID}, ${JSON.stringify(item)}, ${JSON.stringify(yieldKey)})`);
}

// Buys a tile for a city with gold. The tile is one of the tiles of the
// purchases choice. An ok result means the game took the order.
export function purchaseTile(client: TunerClient, playerID: number, cityID: number, x: number, y: number): Promise<ActionResult> {
	return sendAction(client, `SentientSystems_PurchaseTile(${playerID}, ${cityID}, ${x}, ${y})`);
}

// Orders a city to shoot at a tile in its range. An ok result means the game
// took the order, not that the shot has landed.
export function cityAttack(client: TunerClient, playerID: number, cityID: number, x: number, y: number): Promise<ActionResult> {
	return sendAction(client, `SentientSystems_CityAttack(${playerID}, ${cityID}, ${x}, ${y})`);
}
