// The schema for the trade routes section of the state, as the Trade Overview
// shows them. The core mod builds it in
// Scripts/State/SentientSystemsCore_StateTrade.lua.

import { z } from "zod";
import { ROUTE_END } from "../choices/trade-routes.js";

const CITY = z.object({ owner: z.number(), id: z.number(), name: z.string().describe("In the game's language.") });

const ROUTE = z.object({
	trader: z.number().describe("The trader's unit ID."),
	origin: CITY,
	destination: CITY,
	pathBonus: z.boolean().describe("Whether the trading posts on the path add yields to the origin."),
	yields: z.object({
		origin: ROUTE_END.describe("What the origin city receives."),
		destination: ROUTE_END.describe("What the destination city receives."),
	}),
});

export const TRADE = z.object({
	tourismBonus: z.number().describe(
		"The percent of tourism a route adds against the civilization it goes to. A route to a civilization also raises"
			+ " the diplomatic visibility on it by one level, which the diplomacy section shows.",
	),
	outgoing: z.array(ROUTE).describe(
		"The My Routes tab: the routes of the player's cities, those to the player's own cities first, then by the destination's owner.",
	),
	incoming: z.array(ROUTE).describe(
		"The Routes To My Cities tab: routes of other players that end in the player's cities, by the origin's owner.",
	),
});
