// The schema for the governors section of the state: the player's governor titles and each appointed
// governor, with their city, how settled they are, their loyalty pressure, and their promotions, as
// the Governors panel shows them. The core mod builds it in
// Scripts/State/SentientSystemsCore_StateGovernors.lua.

import { z } from "zod";

// Left out without Rise and Fall, which adds governors. titles is the titles the player can still
// spend, and spent the titles spent.
export const GOVERNORS = z.object({
	titles: z.number(),
	spent: z.number(),
	// Each appointed governor in the panel's order: type, such as GOVERNOR_THE_MERCHANT, name, and
	// title, in the game's language. city is where they are assigned, left out while they have none,
	// established is whether they have settled in there, and turnsLeft the turns until they do.
	// neutralized is the turns they are out of action, there above 0 only. loyalty is the loyalty
	// pressure they give their city, turnsToEstablish the turns they take to settle in a city, and
	// promotions the promotions they have, by type. secret is true for a Secret Society, which has
	// neither loyalty nor turns to establish, as its card shows no stats.
	appointed: z.array(z.object({
		type: z.string(),
		name: z.string(),
		title: z.string(),
		city: z.object({ owner: z.number(), id: z.number() }).optional(),
		established: z.boolean().optional(),
		turnsLeft: z.number().optional(),
		neutralized: z.number().optional(),
		secret: z.literal(true).optional(),
		loyalty: z.number().optional(),
		turnsToEstablish: z.number().optional(),
		promotions: z.array(z.string()),
	})),
}).optional();
