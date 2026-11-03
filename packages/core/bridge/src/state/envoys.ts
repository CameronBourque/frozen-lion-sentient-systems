// The schema for the envoys section of the state: the player's envoys and influence, and each met
// city-state, as the City-States screen shows them. The core mod builds it in
// Scripts/State/SentientSystemsCore_StateEnvoys.lua.

import { z } from "zod";

export const ENVOYS = z.object({
	tokens: z.number().describe("The envoys the player can send now."),
	influence: z.object({
		points: z.number(),
		perTurn: z.number(),
		threshold: z.number().describe("The influence points the player needs for the next envoys."),
		envoys: z.number().describe("The envoys each threshold gives."),
	}),
	bonuses: z.record(z.string(), z.array(z.string())).optional().describe(
		"The bonuses at 1, 3, and 6 envoys of each kind of city-state the player has met, such as TRADE, in the game's language. Left out with none met.",
	),
	cityStates: z.array(z.object({
		player: z.number().describe("The city-state's player ID."),
		name: z.string(),
		type: z.string().optional().describe("Its kind, such as TRADE. Left out for a city-state of no kind."),
		envoys: z.number().describe("The player's envoys there."),
		suzerain: z.number().optional().describe(
			"The suzerain's player ID, when it is the player or a player they have met. Left out with no suzerain.",
		),
		suzerainUnmet: z.literal(true).optional().describe(
			"There in place of suzerain for a player they haven't met, as the screen shows Unmet Player.",
		),
		suzerainNeeds: z.number().describe(
			"The envoys the player needs to be suzerain: at least 3, and one more than the most any other player has.",
		),
		suzerainBonus: z.string().optional().describe("The city-state's own suzerain bonus, in the game's language."),
		suzerainBonusDisabled: z.literal(true).optional().describe("There when Gathering Storm turns it off."),
		resources: z.array(z.object({ type: z.string(), amount: z.number() })).optional().describe(
			"The resources the city-state has, which its suzerain gets. With Gathering Storm, a strategic resource's amount is what it gains each turn. Left out with none.",
		),
		quests: z.array(z.object({
			type: z.string(),
			name: z.string(),
			description: z.string(),
			reward: z.string(),
		})).optional().describe("The quests the city-state gives the player, in the game's language. Left out with none."),
		influencedBy: z.array(z.object({
			player: z.number().optional().describe("There when it is the player or a player they have met."),
			unmet: z.literal(true).optional().describe("There in place of player for a player they haven't met."),
			envoys: z.number(),
		})).describe("The players with envoys there, most first. Ties keep the game's order."),
	})).describe("Each city-state the player has met, in the game's order."),
});
