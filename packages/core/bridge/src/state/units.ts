// The schema for the units section of the state: the player's own units, as the unit panel shows
// them. The core mod builds it in Scripts/State/SentientSystemsCore_StateUnits.lua.

import { z } from "zod";

// A unit's or a city garrison's health. The rivals section uses it too.
export const HEALTH = z.object({ value: z.number(), max: z.number() });

export const UNIT = z.object({
	id: z.number(),
	type: z.string(),
	x: z.number(),
	y: z.number(),
	moves: z.object({ left: z.number(), max: z.number() }),
	health: HEALTH,
	// These three are left out for a unit with no experience.
	experience: z.object({ points: z.number(), nextLevel: z.number() }).optional(),
	promotions: z.array(z.string()).optional(),
	availablePromotions: z.array(z.string()).optional(),
});
