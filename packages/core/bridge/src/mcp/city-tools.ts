// The MCP tools that act on a city: its production and its purchases. Each
// description is written for the model. docs/design/core/mod/actions/cities.md
// has the actions.

import type { McpServer } from "@modelcontextprotocol/server";
import { z } from "zod";
import { purchase, purchaseTile, queueProduction, setProduction } from "../actions/cities.js";
import { optionalTile, registerAction } from "./action.js";
import type { ToolContext } from "./context.js";

const SET_PRODUCTION = `Set what one of your cities produces, from the type of an option in get_choices' production for that city, such as UNIT_BUILDER. A unit is a standard unit, not a corps or an army.

A district or a wonder also needs its tile, x and y, from get_placement's tiles, unless the city has placed it already. With queue, the item goes to the end of the city's queue instead, and a full queue is refused.`;

const PURCHASE = `Buy a unit or a building in one of your cities, from the type of an option in get_choices' purchases for that city, such as UNIT_BUILDER. yield is the key it is listed under, gold or faith. No tool buys the districts that purchases lists yet, so produce them with set_production.

A refusal gives the game's reasons, such as gold that falls short.`;

const PURCHASE_TILE = `Buy a tile for one of your cities with gold, from the tiles in get_choices' purchases.gold for that city.`;

const CITY_ID = z.int().describe("The city's id, from get_state.");

export function registerCityTools(server: McpServer, context: ToolContext): void {
	const { client } = context;

	registerAction(server, context, "set_production", SET_PRODUCTION, z.object({
		cityID: CITY_ID,
		item: z.string().describe("The option's type, such as UNIT_BUILDER or DISTRICT_CAMPUS."),
		x: z.int().optional().describe("The tile of a district or a wonder."),
		y: z.int().optional(),
		queue: z.boolean().optional().describe("Add to the end of the queue instead of replacing the current item."),
	}), (playerID, { cityID, item, x, y, queue }) => {
		const tile = optionalTile(x, y);

		if ("reason" in tile) {
			return Promise.resolve(tile);
		}

		return (queue === true ? queueProduction : setProduction)(client, playerID, cityID, item, tile.tile);
	});
	registerAction(server, context, "purchase", PURCHASE, z.object({
		cityID: CITY_ID,
		item: z.string().describe("The option's type, such as UNIT_BUILDER."),
		yield: z.enum(["gold", "faith"]),
	}), (playerID, { cityID, item, yield: yieldKey }) => purchase(client, playerID, cityID, item, yieldKey));
	registerAction(server, context, "purchase_tile", PURCHASE_TILE, z.object({
		cityID: CITY_ID,
		x: z.int(),
		y: z.int(),
	}), (playerID, { cityID, x, y }) => purchaseTile(client, playerID, cityID, { x, y }));
}
