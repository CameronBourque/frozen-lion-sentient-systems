// The schema for the player section of the state: what the top bar shows about
// the player as a whole. The core mod builds it in
// Scripts/State/SentientSystemsCore_StatePlayer.lua.

import { z } from "zod";
import { ERA } from "./era.js";
import { INCOME } from "./income.js";
import { RESOURCES } from "./resources.js";

// An amount the player stores, with what it gains each turn.
const BALANCE = z.object({ balance: z.number(), perTurn: z.number() });

export const PLAYER = z.object({
	gold: BALANCE.extend({
		balance: z.number().describe("Rounded down."),
		perTurn: z.number().describe("Net of the upkeep."),
	}),
	faith: BALANCE,
	science: z.number().describe("Per turn, to one decimal."),
	culture: z.number().describe("Per turn, to one decimal."),
	tourism: z.number().describe("Per turn, to one decimal."),
	income: INCOME,
	resources: RESOURCES,
	era: ERA,
	tradeRoutes: z.object({ active: z.number(), capacity: z.number() }).optional().describe(
		"Left out while the player has no capacity for routes, as the top bar hides it.",
	),
	favor: BALANCE.optional().describe(
		"Diplomatic favor. Left out without Gathering Storm.",
	),
	wmds: z.record(z.string(), z.number()).optional().describe(
		"How many of each device the player has, by type, such as WMD_NUCLEAR_DEVICE, as the top bar shows them. A device at 0 is left out, and so is this field when the player has none.",
	),
});
