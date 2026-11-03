// The schema for the units section of the state. The core mod builds it in
// Scripts/State/SentientSystemsCore_StateUnits.lua.

import { z } from "zod";

// A unit's or a city garrison's health. The rivals section uses it too.
export const HEALTH = z.object({
	value: z.number().describe("The most damage less the damage taken, as the unit panel shows it."),
	max: z.number(),
});

export const UNIT = z.object({
	id: z.number(),
	type: z.string().describe("Such as UNIT_SCOUT."),
	x: z.number(),
	y: z.number(),
	moves: z.object({ left: z.number(), max: z.number() }),
	health: HEALTH,
	experience: z.object({
		points: z.number(),
		nextLevel: z.number().describe("A unit whose points reach this can promote once it has moves."),
	}).optional().describe("Left out, with the two fields below, for a unit with no experience."),
	promotions: z.array(z.string()).optional().describe("The promotions the unit has, by type."),
	availablePromotions: z.array(z.string()).optional().describe(
		"The promotions the unit can pick now, by type, such as PROMOTION_RANGER. It's empty until the unit can promote, and while it has no moves left.",
	),
});
