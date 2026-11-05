// The schema for the scoreboard section of the state: each major player's
// score and the leader panel's numbers.

import { z } from "zod";

export const SCOREBOARD = z.array(z.object({
	player: z.number().optional().describe(
		"The player's ID. Left out for a player the player has not met, as the tab shows them as Unmet Player, so only the entry's place names them.",
	),
	score: z.number(),
	categories: z.array(z.object({
		type: z.string().describe("Such as CATEGORY_CIVICS."),
		name: z.string().describe("In the game's language."),
		score: z.number(),
	})).describe("What the score is made of, in the game's order, as the tab's details show it."),
	military: z.number().optional().describe(
		"The leader panel's numbers, here and below, are left out for a player the player has not met.",
	),
	science: z.number().optional().describe("Per turn."),
	culture: z.number().optional().describe("Per turn."),
	gold: z.number().optional().describe("The balance."),
	faith: z.number().optional().describe("The balance."),
	favor: z.number().optional().describe("Left out without Gathering Storm, and when the diplomatic victory is off."),
})).describe(
	"One entry for each living major player, highest score first and, for equal scores, in ID order. Teams aren't grouped.",
);
