// The MCP tools that move units, give them orders, and start a trader's route.
// Each description is written for the model.
// docs/design/core/mod/actions/units.md has the orders.

import type { McpServer } from "@modelcontextprotocol/server";
import { z } from "zod";
import { tradeRoute } from "../actions/trade.js";
import { moveUnit, unitAction, type UnitOrder } from "../actions/units.js";
import { optionalTile, registerAction } from "./action.js";
import type { ToolContext } from "./context.js";

type OrderAction = UnitOrder["action"];

// Each order with what it does and the fields it takes, for the description.
// The record type makes it list every order of the action API.
const ORDERS: Record<OrderAction, string> = {
	fortify: "Fortify until woken.",
	sleep: "Sleep until woken.",
	skip: "Skip this turn.",
	alert: "Sleep until an enemy comes into view.",
	heal: "Fortify until healed.",
	wake: "Wake a sleeping or fortified unit.",
	delete: "Disband the unit.",
	found_city: "Found a city on the unit's tile.",
	pillage: "Pillage the improvement or district on the unit's tile, then the road on a second order.",
	plunder: "Plunder the enemy trade route on the unit's tile.",
	concert: "Start a rock band's concert on its tile.",
	activate: "Use a great person's ability on its tile, such as a great engineer's production for a wonder.",
	harvest_wonder: "The game's harvest wonder command for a great person.",
	found_religion: "Found a religion with a prophet on its Holy Site. Then choose its name and beliefs.",
	spread_religion: "Spread the unit's religion from the city it is in. It needs a charge left.",
	remove_heresy: "Remove other religions from the city with an inquisitor.",
	heal_followers: "Heal the wounded religious units on the unit's tile or next to it.",
	evangelize_belief: "Earn one more belief with an apostle. Then choose the belief.",
	launch_inquisition: "Launch an inquisition with an apostle.",
	condemn_heretic: "The game's condemn heretic command, with which a military unit kills an enemy religious unit.",
	remove_feature: "Remove the feature on the unit's tile with a builder.",
	harvest: "Harvest the resource on the unit's tile with a builder.",
	repair: "Repair the pillaged improvement, or the road, on the unit's tile.",
	remove_improvement: "Remove the improvement on the unit's tile.",
	clear_fallout: "Clear the nuclear fallout on the unit's tile for a build charge.",
	add_production: "Add a builder's or engineer's production to what the city builds, from the city or the district's tile.",
	upgrade: "Upgrade the unit, for gold and any resources.",
	exit_formation: "Split a corps or an army.",
	form_corps: "Join the unit in with to form a corps. Without with, the reason lists the units that can join.",
	form_army: "Join the unit in with to form an army. Without with, the reason lists the units that can join.",
	enter_formation: "Join the formation of the unit in with.",
	promote: "Take the promotion in promotion, such as PROMOTION_BATTLECRY.",
	build_road: "Build a road with a military engineer. route is optional, and the game builds the best route you have.",
	improve: "Build the improvement in improvement, such as IMPROVEMENT_FARM, on the unit's tile with a builder.",
	attack: "Attack the tile at x and y, as melee, ranged, air, or a ship's coastal raid. It never declares war. A refusal lists the targets.",
	priority_target: "Hit the support or civilian unit escorted on the tile at x and y.",
	rebase: "Move an air unit to another base at x and y. A refusal names the nearest tiles that work.",
	deploy: "The game's deploy command for an air unit, to the tile at x and y.",
	airlift: "Airlift a land unit to the tile at x and y.",
	paradrop: "Drop a land unit on the tile at x and y.",
	wmd_strike: "Launch the device in device, such as WMD_NUCLEAR_DEVICE, at the tile at x and y.",
};

const ACTIONS = Object.keys(ORDERS) as [OrderAction, ...OrderAction[]];

const MOVE_UNIT = `Move one of your units to a tile at x and y, by the game's own path, over as many turns as it takes. It never attacks and never declares war, so attack with unit_action.

The game may finish a move after the call returns, so read get_state for the unit's new position.`;

const UNIT_ACTION = `Give one of your units an order. A failed order returns the game's reason, or the core mod's when the game gives none, such as which units can join a formation.

${ACTIONS.map((action) => `- ${action}: ${ORDERS[action]}`).join("\n")}`;

const START_TRADE_ROUTE = `Start a trade route from the city a trader stands in, to a destination from get_choices' tradeRoutes for that trader. A destination is named by its owner and id. The trader then travels the route.

get_trade_routes lists a city's destinations before a trader is there. A refusal names why, such as a trader that already has a route or no free route slot.`;

const UNIT_ID = z.int().describe("The unit's id, from get_state.");
const COORDINATE = z.int().optional();

export function registerUnitTools(server: McpServer, context: ToolContext): void {
	const { client } = context;

	registerAction(server, context, "move_unit", MOVE_UNIT, z.object({
		unitID: UNIT_ID,
		x: z.int(),
		y: z.int(),
	}), (playerID, { unitID, x, y }) => moveUnit(client, playerID, unitID, { x, y }));
	registerAction(server, context, "unit_action", UNIT_ACTION, z.object({
		unitID: UNIT_ID,
		action: z.enum(ACTIONS),
		x: COORDINATE.describe("The target tile, for the orders that take one."),
		y: COORDINATE,
		with: z.int().optional().describe("The other unit's id, for form_corps, form_army, and enter_formation."),
		promotion: z.string().optional().describe("For promote."),
		improvement: z.string().optional().describe("For improve."),
		route: z.string().optional().describe("For build_road, such as ROUTE_MODERN_ROAD."),
		device: z.string().optional().describe("For wmd_strike, such as WMD_NUCLEAR_DEVICE."),
	}), (playerID, { unitID, x, y, ...order }) => {
		const tile = optionalTile(x, y);

		if ("reason" in tile) {
			return Promise.resolve(tile);
		}

		// The core mod checks that the order has the fields it needs, and
		// says which are missing.
		return unitAction(client, playerID, unitID, { ...order, ...tile.tile } as UnitOrder);
	});
	registerAction(server, context, "start_trade_route", START_TRADE_ROUTE, z.object({
		unitID: UNIT_ID.describe("The trader's id, from tradeRoutes."),
		owner: z.int().describe("The destination city's owner."),
		cityID: z.int().describe("The destination city's id."),
	}), (playerID, { unitID, owner, cityID }) => tradeRoute(client, playerID, unitID, owner, cityID));
}
