// The schema for the player section of the state: what the top bar shows about the player as a
// whole. The core mod builds it in Scripts/State/SentientSystemsCore_StatePlayer.lua.

import { z } from "zod";
import { ERA } from "./era.js";
import { INCOME } from "./income.js";
import { RESOURCES } from "./resources.js";

// gold and faith have the balance and the income per turn, as the top bar shows them, and gold's
// income is net of the upkeep. science, culture, and tourism are per turn, each to one decimal.
// tradeRoutes is left out while the player has no capacity for routes. favor is left out without
// Gathering Storm. income is in income.ts, resources in resources.ts, and era in era.ts.
export const PLAYER = z.object({
	gold: z.object({ balance: z.number(), perTurn: z.number() }),
	faith: z.object({ balance: z.number(), perTurn: z.number() }),
	science: z.number(),
	culture: z.number(),
	tourism: z.number(),
	income: INCOME,
	resources: RESOURCES,
	era: ERA,
	tradeRoutes: z.object({ active: z.number(), capacity: z.number() }).optional(),
	favor: z.object({ balance: z.number(), perTurn: z.number() }).optional(),
});
