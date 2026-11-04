// The schema for the governors section of the state: the player's governor
// titles and each appointed governor, as the Governors panel shows them. The
// core mod builds it in Scripts/State/SentientSystemsCore_StateGovernors.lua.

import { z } from "zod";

export const GOVERNORS = z.object({
	titles: z.number().describe("The titles the player can still spend."),
	spent: z.number().describe("The titles spent."),
	appointed: z.array(z.object({
		type: z.string().describe("Such as GOVERNOR_THE_MERCHANT."),
		name: z.string().describe("In the game's language."),
		title: z.string().describe("In the game's language."),
		city: z.object({ owner: z.number(), id: z.number() }).optional().describe(
			"Where they are assigned. Left out while they have none.",
		),
		established: z.boolean().optional().describe("Whether they have settled in there."),
		turnsLeft: z.number().optional().describe("The turns until they settle in."),
		neutralized: z.number().optional().describe("The turns they are out of action. There above 0 only."),
		secret: z.literal(true).optional().describe(
			"True for a Secret Society, which has neither loyalty nor turns to establish, as its card shows no stats.",
		),
		loyalty: z.number().optional().describe("The loyalty pressure they give their city."),
		turnsToEstablish: z.number().optional().describe("The turns they take to settle in a city."),
		promotions: z.array(z.string()).describe("By type, in the order the panel lists them."),
	})).describe("Each appointed governor, in the panel's order."),
}).optional().describe("Left out without Rise and Fall, which adds governors.");
