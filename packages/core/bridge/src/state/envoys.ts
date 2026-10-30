// The schema for the envoys section of the state: the player's envoy tokens and influence, the
// bonuses of each kind of city-state, and each met city-state's envoys, suzerain, suzerain bonus,
// resources, quests, and the players with envoys there, as the City-States screen shows them. The
// core mod builds it in Scripts/State/SentientSystemsCore_StateEnvoys.lua.

import { z } from "zod";

export const ENVOYS = z.object({
	// The envoys the player can send now.
	tokens: z.number(),
	// The influence points the player has, earns per turn, and needs for the next envoys, and the
	// envoys each threshold gives.
	influence: z.object({ points: z.number(), perTurn: z.number(), threshold: z.number(), envoys: z.number() }),
	// The bonuses at 1, 3, and 6 envoys of each kind of city-state the player has met, such as TRADE,
	// in the game's language. Left out with none met.
	bonuses: z.record(z.string(), z.array(z.string())).optional(),
	// Each city-state the player has met, in the game's order. player is its player ID, and type its
	// kind, such as TRADE, left out for a city-state of no kind. envoys is the player's envoys there.
	// suzerain is the suzerain's player ID when it is the player or a player they have met, and
	// suzerainUnmet is true in its place for a player they haven't met. Both are left out with no
	// suzerain. suzerainNeeds is the envoys the player needs to be suzerain.
	cityStates: z.array(z.object({
		player: z.number(),
		name: z.string(),
		type: z.string().optional(),
		envoys: z.number(),
		suzerain: z.number().optional(),
		suzerainUnmet: z.literal(true).optional(),
		suzerainNeeds: z.number(),
		// The city-state's own suzerain bonus, in the game's language, and suzerainBonusDisabled,
		// true when Gathering Storm turns it off.
		suzerainBonus: z.string().optional(),
		suzerainBonusDisabled: z.literal(true).optional(),
		// The resources the city-state has, which its suzerain gets. With Gathering Storm, a
		// strategic resource's amount is what it gains each turn. Left out with none.
		resources: z.array(z.object({ type: z.string(), amount: z.number() })).optional(),
		// The quests the city-state gives the player, in the game's language. Left out with none.
		quests: z.array(z.object({ type: z.string(), name: z.string(), description: z.string(), reward: z.string() })).optional(),
		// The players with envoys there, most first. Each has player, its ID, when it is the player
		// or a player they have met, or unmet, true for a player they haven't met.
		influencedBy: z.array(z.object({
			player: z.number().optional(),
			unmet: z.literal(true).optional(),
			envoys: z.number(),
		})),
	})),
});
