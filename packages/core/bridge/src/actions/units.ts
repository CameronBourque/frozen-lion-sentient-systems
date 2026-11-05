// The unit actions, which run the calls in
// Scripts/Actions/SentientSystemsCore_ActionsUnits.lua.

import type { TunerClient } from "../tuner/client.js";
import { type ActionResult, sendAction } from "./actions.js";

export type UnitOrder =
	| { action: "fortify" | "sleep" | "skip" | "alert" | "heal" | "wake" | "delete" }
	| { action: "promote"; promotion: string };

// Moves a unit to a tile by the game's own path, over as many turns as it
// takes. An ok result means the game took the request, not that the unit has
// arrived.
export function moveUnit(client: TunerClient, playerID: number, unitID: number, x: number, y: number): Promise<ActionResult> {
	return sendAction(client, `SentientSystems_MoveUnit(${playerID}, ${unitID}, ${x}, ${y})`);
}

// Gives a unit an order: a stance, a wake, a delete, or a promotion. A
// promotion is a type from the unit's choices.
export function unitAction(client: TunerClient, playerID: number, unitID: number, order: UnitOrder): Promise<ActionResult> {
	const promotion = order.action === "promote" ? JSON.stringify(order.promotion) : "nil";

	return sendAction(client, `SentientSystems_UnitAction(${playerID}, ${unitID}, ${JSON.stringify(order.action)}, nil, nil, ${promotion})`);
}
