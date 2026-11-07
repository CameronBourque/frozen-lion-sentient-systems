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
	activity: z.enum(["awake", "sleep", "skip", "sentry", "heal", "intercept", "operation"]).optional().describe(
		"What the unit is doing. Skip is skip turn. Sentry is fortified or on alert, and fortified says which. Operation is a fortify that hasn't taken yet, a trader on its route, or a spy on a mission. Left out for a unit with no activity.",
	),
	fortified: z.literal(true).optional().describe("Left out unless the unit is not awake and has fortify turns, as the unit list marks it."),
	attacksLeft: z.number().optional().describe("Left out for a unit that can't attack."),
	buildCharges: z.number().optional().describe("The builder charges left. Left out at 0."),
	formation: z.enum(["corps", "army"]).optional().describe("A corps or army, or a fleet or armada at sea. Left out for a single unit."),
	religion: z.string().optional().describe("The religion of a religious unit, such as RELIGION_CHRISTIANITY. Left out for any other unit."),
	spreadCharges: z.number().optional().describe("The spreads left. Left out at 0."),
	healCharges: z.number().optional().describe("The heals left. Left out at 0."),
	greatPerson: z.object({
		class: z.string().describe("Such as GREAT_PERSON_CLASS_PROPHET."),
		individual: z.string().optional().describe("Such as GREAT_PERSON_INDIVIDUAL_ZHANG_QIAN. Left out when the game has no row for it."),
		charges: z.number().describe("The action charges left. The unit panel shows them only above 0."),
	}).optional().describe("Left out for a unit that isn't a great person."),
	experience: z.object({
		points: z.number(),
		nextLevel: z.number().describe("A unit whose points reach this can promote once it has moves."),
	}).optional().describe("Left out, with the two fields below, for a unit with no experience."),
	promotions: z.array(z.string()).optional().describe("The promotions the unit has, by type."),
	availablePromotions: z.array(z.string()).optional().describe(
		"The promotions the unit can pick now, by type, such as PROMOTION_RANGER. It's empty until the unit can promote, and while it has no moves left.",
	),
});
