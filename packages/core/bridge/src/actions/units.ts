// The unit actions, which run the calls in
// Scripts/Actions/SentientSystemsCore_ActionsUnits.lua.

import type { Position } from "../schemas.js";
import type { TunerClient } from "../tuner/client.js";
import { type ActionResult, sendAction } from "./actions.js";

export type UnitOrder =
	| { action: "fortify" | "sleep" | "skip" | "alert" | "heal" | "wake" | "delete" | "found_city" | "pillage" | "plunder" }
	| { action: "activate" | "harvest_wonder" | "found_religion" | "spread_religion" | "remove_heresy" | "heal_followers" | "evangelize_belief" | "launch_inquisition" | "condemn_heretic" }
	| { action: "remove_feature" | "harvest" | "repair" | "remove_improvement" | "clear_fallout" | "add_production" }
	| { action: "upgrade" | "exit_formation" }
	| { action: "form_corps" | "form_army" | "enter_formation"; with: number }
	| { action: "promote"; promotion: string }
	| { action: "build_road"; route?: string }
	| { action: "improve"; improvement: string }
	| ({ action: "attack" | "priority_target" | "rebase" | "deploy" | "airlift" | "paradrop" } & Position)
	| ({ action: "wmd_strike"; device: string } & Position);

// The fields of an order that the core mod reads as its type argument. An order
// has at most one of them.
const ARGUMENT_FIELDS = ["promotion", "improvement", "route", "with", "device"] as const;

type ArgumentField = (typeof ARGUMENT_FIELDS)[number];

// Returns the order's type argument as Lua: its argument field, or nil.
function orderArgument(order: UnitOrder): string {
	const field = ARGUMENT_FIELDS.find((name) => name in order);
	const value = field === undefined ? undefined : (order as Partial<Record<ArgumentField, string | number>>)[field];

	return value === undefined ? "nil" : JSON.stringify(value);
}

// Moves a unit to a tile by the game's own path, over as many turns as it
// takes. An ok result means the game took the request, not that the unit has
// arrived.
export function moveUnit(client: TunerClient, playerID: number, unitID: number, position: Position): Promise<ActionResult> {
	return sendAction(client, `SentientSystems_MoveUnit(${playerID}, ${unitID}, ${position.x}, ${position.y})`);
}

// Gives a unit an order, such as a stance, an upgrade, a job on its tile, a
// plunder of the trade route through it, a religious order, an attack or
// priority target, an air move to a tile, or a WMD strike. A promotion, an
// improvement, a route, the unit to join a formation with, or the device, such
// as WMD_NUCLEAR_DEVICE, goes in its own field.
export function unitAction(client: TunerClient, playerID: number, unitID: number, order: UnitOrder): Promise<ActionResult> {
	const tile = "x" in order ? `${order.x}, ${order.y}` : "nil, nil";

	return sendAction(client, `SentientSystems_UnitAction(${playerID}, ${unitID}, ${JSON.stringify(order.action)}, ${tile}, ${orderArgument(order)})`);
}
