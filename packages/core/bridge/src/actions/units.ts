// The unit actions, which run the calls in
// Scripts/Actions/SentientSystemsCore_ActionsUnits.lua.

import type { TunerClient } from "../tuner/client.js";
import { type ActionResult, sendAction } from "./actions.js";

export type UnitOrder =
	| { action: "fortify" | "sleep" | "skip" | "alert" | "heal" | "wake" | "delete" | "found_city" | "pillage" }
	| { action: "remove_feature" | "harvest" | "repair" | "remove_improvement" }
	| { action: "upgrade" }
	| { action: "promote"; promotion: string }
	| { action: "build_road"; route?: string }
	| { action: "improve"; improvement: string }
	| { action: "attack"; x: number; y: number };

// Moves a unit to a tile by the game's own path, over as many turns as it
// takes. An ok result means the game took the request, not that the unit has
// arrived.
export function moveUnit(client: TunerClient, playerID: number, unitID: number, x: number, y: number): Promise<ActionResult> {
	return sendAction(client, `SentientSystems_MoveUnit(${playerID}, ${unitID}, ${x}, ${y})`);
}

// Gives a unit an order, such as a stance, an upgrade, a job on its tile, or
// an attack. A promotion, an improvement, or a route goes in its own field.
export function unitAction(client: TunerClient, playerID: number, unitID: number, order: UnitOrder): Promise<ActionResult> {
	const type = "promotion" in order ? order.promotion : "improvement" in order ? order.improvement : "route" in order ? order.route : undefined;
	const argument = type === undefined ? "nil" : JSON.stringify(type);
	const tile = order.action === "attack" ? `${order.x}, ${order.y}` : "nil, nil";

	return sendAction(client, `SentientSystems_UnitAction(${playerID}, ${unitID}, ${JSON.stringify(order.action)}, ${tile}, ${argument})`);
}
