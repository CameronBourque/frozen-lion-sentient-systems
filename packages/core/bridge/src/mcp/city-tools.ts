// The MCP tools that act on a city: its production, its purchases, its shot,
// a silo's strike, and a captured city's fate. Each description is written for
// the model. docs/design/core/mod/actions/ has the actions.

import type { McpServer } from "@modelcontextprotocol/server";
import { z } from "zod";
import { cityAttack, purchase, purchaseTile, queueProduction, setProduction } from "../actions/cities.js";
import { CITY_DIRECTIVES, decideCity } from "../actions/city-fate.js";
import { siloStrike } from "../actions/wmds.js";
import { optionalTile, registerAction } from "./action.js";
import type { ToolContext } from "./context.js";

const SET_PRODUCTION = `Set what one of your cities produces, from the type of an option in get_choices' production for that city, such as UNIT_BUILDER. A unit is a standard unit, not a corps or an army.

A district or a wonder also needs its tile, x and y, from get_placement's tiles, unless the city has placed it already. With queue, the item goes to the end of the city's queue instead, and a full queue is refused.`;

const PURCHASE = `Buy a unit or a building in one of your cities, from the type of an option in get_choices' purchases for that city, such as UNIT_BUILDER. yield is the key it is listed under, gold or faith. No tool buys the districts that purchases lists yet, so produce them with set_production.

A refusal gives the game's reasons, such as gold that falls short.`;

const PURCHASE_TILE = `Buy a tile for one of your cities with gold, from the tiles in get_choices' purchases.gold for that city.`;

const CITY_ATTACK = `Have one of your cities shoot at the tile at x and y in its range. Ok means the game took the order, not that the shot landed.`;

const SILO_STRIKE = `Launch a nuclear device from one of your missile silos at the tile at x and y. get_state's wmdLaunchers lists, for each device, the silos that can launch it now.

It checks the device and your stockpile, the silo, the tile, the range, and the war check, in that order. A refusal gives how many tiles the silo can hit and how far, not the list.`;

const DECIDE_CITY = `Decide the fate of a captured or rebelled city, from get_choices' cityFates. The game offers one city at a time.

directive is the type of one of that city's options: KEEP, RAZE, LIBERATE_FOUNDER, or LIBERATE_PREVIOUS_OWNER for a captured city, and KEEP or REJECT for a rebelled one. A refusal lists the city's options.`;

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
	registerAction(server, context, "city_attack", CITY_ATTACK, z.object({
		cityID: CITY_ID,
		x: z.int(),
		y: z.int(),
	}), (playerID, { cityID, x, y }) => cityAttack(client, playerID, cityID, { x, y }));
	registerAction(server, context, "silo_strike", SILO_STRIKE, z.object({
		siloX: z.int().describe("The silo's tile, from get_state's wmdLaunchers."),
		siloY: z.int(),
		x: z.int().describe("The target tile."),
		y: z.int(),
		device: z.string().describe("Such as WMD_NUCLEAR_DEVICE or WMD_THERMONUCLEAR_DEVICE."),
	}), (playerID, { siloX, siloY, x, y, device }) => siloStrike(client, playerID, { x: siloX, y: siloY }, { x, y }, device));
	registerAction(server, context, "decide_city", DECIDE_CITY, z.object({
		cityID: z.int().describe("The city in cityFates."),
		directive: z.enum(CITY_DIRECTIVES),
	}), (playerID, { cityID, directive }) => decideCity(client, playerID, cityID, directive));
}
