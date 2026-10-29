// The schema for the cities section of the state: the player's own cities, as the city panel shows
// them. The core mod builds it in Scripts/State/SentientSystemsCore_StateCities.lua.

import { z } from "zod";
import { HEALTH } from "./units.js";

// A city's defense, as its banner shows it. walls is left out for a city with none. The rivals
// section uses it too.
export const DEFENSE = z.object({ strength: z.number(), garrison: HEALTH, walls: HEALTH.optional() });

export const CITY = z.object({
	id: z.number(),
	name: z.string(),
	x: z.number(),
	y: z.number(),
	population: z.number(),
	// warWeariness is the amenities lost to war weariness.
	amenities: z.object({ have: z.number(), need: z.number(), mood: z.string().optional(), warWeariness: z.number() }),
	defense: DEFENSE,
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
		// The growth rate status of the City Status tab of Reports.
		rate: z.enum(["normal", "slowed", "halted", "accelerated"]),
		turnsUntilGrowth: z.number().optional(),
		turnsUntilLoss: z.number().optional(),
	}),
	// The city's governor, with its type and whether it has settled in. Left out for none, and in a game
	// without the Rise and Fall expansion.
	governor: z.object({ type: z.string(), established: z.boolean() }).optional(),
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
