// The schema for the envoys section of the state: the player's envoy tokens and influence, and each
// met city-state's envoys and suzerain, as the City-States screen shows them. The core mod builds it
// in Scripts/State/SentientSystemsCore_StateEnvoys.lua.

import { z } from "zod";

export const ENVOYS = z.object({
	// The envoys the player can send now.
	tokens: z.number(),
	// The influence points the player has, earns per turn, and needs for the next envoys, and the
	// envoys each threshold gives.
	influence: z.object({ points: z.number(), perTurn: z.number(), threshold: z.number(), envoys: z.number() }),
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
	})),
});
