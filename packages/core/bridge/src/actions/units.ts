// The unit actions, which run the calls in
// Scripts/Actions/SentientSystemsCore_ActionsUnits.lua.

import type { TunerClient } from "../tuner/client.js";
import { type ActionResult, sendAction } from "./actions.js";

export type UnitOrder =
	| { action: "fortify" | "sleep" | "skip" | "alert" | "heal" | "wake" | "delete" | "found_city" | "pillage" }
	| { action: "promote"; promotion: string }
	| { action: "improve"; improvement: string };

// Moves a unit to a tile by the game's own path, over as many turns as it
// takes. An ok result means the game took the request, not that the unit has
// arrived.
export function moveUnit(client: TunerClient, playerID: number, unitID: number, x: number, y: number): Promise<ActionResult> {
	return sendAction(client, `SentientSystems_MoveUnit(${playerID}, ${unitID}, ${x}, ${y})`);
}

// Gives a unit an order: a stance, a wake, a delete, a promotion, or a job on
// the tile it stands on. A promotion or an improvement is a type from the
// unit's choices.
export function unitAction(client: TunerClient, playerID: number, unitID: number, order: UnitOrder): Promise<ActionResult> {
	const type = "promotion" in order ? order.promotion : "improvement" in order ? order.improvement : undefined;
	const argument = type === undefined ? "nil" : JSON.stringify(type);

	return sendAction(client, `SentientSystems_UnitAction(${playerID}, ${unitID}, ${JSON.stringify(order.action)}, nil, nil, ${argument})`);
}
