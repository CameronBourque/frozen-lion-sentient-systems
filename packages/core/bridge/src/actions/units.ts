// The unit actions, which run the calls in
// Scripts/Actions/SentientSystemsCore_ActionsUnits.lua.

import type { Position } from "../schemas.js";
import type { TunerClient } from "../tuner/client.js";
import { type ActionResult, sendAction } from "./actions.js";

export type UnitOrder =
	| { action: "fortify" | "sleep" | "skip" | "alert" | "heal" | "wake" | "delete" | "found_city" | "pillage" | "plunder" }
	| { action: "activate" | "harvest_wonder" | "found_religion" | "spread_religion" | "remove_heresy" | "heal_followers" | "condemn_heretic" }
	| { action: "remove_feature" | "harvest" | "repair" | "remove_improvement" | "add_production" }
	| { action: "upgrade" | "exit_formation" }
	| { action: "form_corps" | "form_army" | "enter_formation"; with: number }
	| { action: "promote"; promotion: string }
	| { action: "build_road"; route?: string }
	| { action: "improve"; improvement: string }
	| ({ action: "attack" | "priority_target" | "rebase" | "deploy" | "airlift" | "paradrop" } & Position);

// Moves a unit to a tile by the game's own path, over as many turns as it
// takes. An ok result means the game took the request, not that the unit has
// arrived.
export function moveUnit(client: TunerClient, playerID: number, unitID: number, position: Position): Promise<ActionResult> {
	return sendAction(client, `SentientSystems_MoveUnit(${playerID}, ${unitID}, ${position.x}, ${position.y})`);
}

// Gives a unit an order, such as a stance, an upgrade, a job on its tile, a
// plunder of the trade route through it, a religious order, an attack or
// priority target, or an air move to a tile. A promotion, an improvement, a
// route, or the unit to join a formation with goes in its own field.
export function unitAction(client: TunerClient, playerID: number, unitID: number, order: UnitOrder): Promise<ActionResult> {
	const type = "promotion" in order ? order.promotion : "improvement" in order ? order.improvement : "route" in order ? order.route : "with" in order ? order.with : undefined;
	const argument = type === undefined ? "nil" : JSON.stringify(type);
	const tile = "x" in order ? `${order.x}, ${order.y}` : "nil, nil";

	return sendAction(client, `SentientSystems_UnitAction(${playerID}, ${unitID}, ${JSON.stringify(order.action)}, ${tile}, ${argument})`);
}
