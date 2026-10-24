// The schema for the cities section of the state: the player's own cities, as the city panel shows
// them. The core mod builds it in Scripts/State/SentientSystemsCore_StateCities.lua.

import { z } from "zod";

export const CITY = z.object({
	id: z.number(),
	name: z.string(),
	x: z.number(),
	y: z.number(),
	population: z.number(),
	amenities: z.object({ have: z.number(), need: z.number(), mood: z.string().optional() }),
	districts: z.array(z.object({
		type: z.string(),
		x: z.number(),
		y: z.number(),
		complete: z.boolean(),
		pillaged: z.boolean(),
		buildings: z.array(z.object({ type: z.string(), pillaged: z.boolean() })),
	})),
	growth: z.object({
		foodSurplus: z.number(),
		housing: z.number(),
		turnsUntilGrowth: z.number().optional(),
		turnsUntilLoss: z.number().optional(),
	}),
	// Only in a game with the Rise and Fall expansion.
	loyalty: z.object({ value: z.number(), max: z.number(), perTurn: z.number() }).optional(),
	// Left out when the city produces nothing.
	production: z.object({ type: z.string().optional(), turnsLeft: z.number() }).optional(),
	yields: z.object({
		food: z.number(),
		production: z.number(),
		gold: z.number(),
		science: z.number(),
		culture: z.number(),
		faith: z.number(),
	}),
});
