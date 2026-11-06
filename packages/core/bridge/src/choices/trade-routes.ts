// The schema for the trade route choice: the destinations of each idle trader
// in a city, as the route chooser lists them. All text is in the game's
// language.

import { z } from "zod";

export const ROUTE_END = z.object({
	yields: z.array(z.object({
		type: z.string().describe("Such as YIELD_GOLD."),
		amount: z.number().describe("Rounded to one decimal, as the chooser shows it."),
	})).describe("What this end of the route receives. Yields of zero are left out."),
	pressure: z.object({
		religion: z.string().describe("Such as RELIGION_BUDDHISM."),
		amount: z.number(),
	}).optional().describe(
		"The religious pressure this end receives from the origin's majority religion. Left out when there is none.",
	),
});

const DESTINATION = z.object({
	owner: z.number(),
	id: z.number(),
	name: z.string(),
	distance: z.number().describe("Plots from the origin city, ignoring the path."),
	tradingPost: z.boolean().describe("Whether the origin's owner has a trading post in the city."),
	pathBonus: z.boolean().describe("Whether the trading posts on the path add yields to the origin."),
	quest: z.string().optional().describe("The city-state quest a route to the city completes."),
	origin: ROUTE_END.describe("What the trader's city receives."),
	destination: ROUTE_END.describe("What the destination city receives."),
});

export const TRADE_ROUTES_CHOICE = z.array(z.object({
	unit: z.number().describe("The trader's unit ID."),
	name: z.string(),
	city: z.object({ owner: z.number(), id: z.number(), name: z.string() }).describe("The city the route starts from."),
	destinations: z.array(DESTINATION).describe(
		"The cities the game lets the trader start a route to, with a path from the origin, the player's own first.",
	),
})).optional().describe("Left out when no idle trader stands in a city.");
