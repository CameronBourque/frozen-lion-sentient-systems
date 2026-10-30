// The schema for the resources part of the player section of the state: each strategic, luxury, and
// bonus resource the player has, where it comes from, and, with Gathering Storm, the strategic
// stockpiles, as the Resources tab of Reports shows them. The core mod builds it in
// Scripts/State/SentientSystemsCore_StatePlayerResources.lua.

import { z } from "zod";

const CITY = z.object({ owner: z.number(), id: z.number() });

// Where an amount of a resource comes from: a city, with city and name, that owns it, a deal, with the
// other player and the turns left, which is negative for a resource the player sends, a suzerain, with
// the city-state's player ID, whose export the player gets, and, with Gathering Storm, units and power
// for what they use each turn, reserve for what is reserved, and cityStates for what city-states send.
// other is the game's Gameplay Bonuses, the amount that no source explains. amount is negative for
// what is used.
const SOURCE = z.discriminatedUnion("kind", [
	z.object({ kind: z.literal("city"), city: CITY, name: z.string(), amount: z.number() }),
	z.object({ kind: z.literal("deal"), player: z.number(), turnsLeft: z.number(), amount: z.number() }),
	z.object({ kind: z.literal("suzerain"), player: z.number(), amount: z.number() }),
	z.object({ kind: z.enum(["units", "power", "reserve", "cityStates", "other"]), amount: z.number() }),
]);

// Each resource has type, such as RESOURCE_IRON, name, class, sources, and cities, the cities that the
// game gives it to, each with the amount, left out for none. total is the sum of the sources. With
// Gathering Storm a strategic resource has perTurn, which is what it adds to the stockpile each turn,
// in place of total, and stockpile and max, as the strip at the bottom of the screen shows them.
export const RESOURCES = z.array(z.object({
	type: z.string(),
	name: z.string(),
	class: z.enum(["strategic", "luxury", "bonus"]),
	sources: z.array(SOURCE),
	cities: z.array(z.object({ city: CITY, amount: z.number() })).optional(),
	total: z.number().optional(),
	perTurn: z.number().optional(),
	stockpile: z.number().optional(),
	max: z.number().optional(),
}));
