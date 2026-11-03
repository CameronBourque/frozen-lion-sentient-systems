// The schema for the era part of the player section of the state, as the Era Progress panel shows
// it. The core mod builds it in Scripts/State/SentientSystemsCore_StatePlayerEra.lua.

import { z } from "zod";

const AGE = z.enum(["dark", "normal", "golden", "heroic"]);

export const ERA = z.object({
	type: z.string().describe("The era, such as ERA_RENAISSANCE."),
	name: z.string().describe("In the game's language."),
	score: z.number().describe("The player's era score."),
	age: AGE.describe("The age the player is in."),
	scoreBreakdown: z.array(z.object({
		source: z.string().describe("The game's text."),
		points: z.number(),
	})).describe("What the score is made of, with the earlier eras as one entry."),
	effects: z.object({
		citizenLoyalty: z.number().describe("The loyalty pressure each of the player's citizens exerts in their city."),
		dedications: z.array(z.object({
			type: z.string(),
			text: z.string().describe("The text of its bonus for the age."),
		})).describe("The active dedications."),
	}),
	civilizations: z.array(z.object({ player: z.number(), age: AGE })).describe(
		"The players the player has met, with their ages, in the panel's order.",
	),
	unmet: z.number().describe("The number of other players the player hasn't met, which the panel shows with no age."),
	final: z.literal(true).optional().describe("There in the final era, which has no next era."),
	nextAge: z.enum(["dark", "normal", "golden"]).optional().describe(
		"The age the score earns for the next era. Left out in the final era.",
	),
	thresholds: z.object({
		normal: z.number().optional().describe("Left out in the Dramatic Ages mode."),
		golden: z.number(),
	}).optional().describe("The score the next normal and golden age need. Left out in the final era."),
	turnsUntilNext: z.object({ min: z.number(), max: z.number() }).optional().describe(
		"The least and the most turns until the era ends, the same once its countdown has started. Left out in the final era.",
	),
}).optional().describe("Left out in a game without the Rise and Fall expansion, which adds ages.");
