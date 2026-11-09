// The schema for the tech and civic choices, as the research and civics
// choosers list them. A tech's prerequisites come from the tech tree.

import { z } from "zod";
import { BOOST } from "../schemas.js";

export const RESEARCH_OPTION = z.object({
	type: z.string().describe("Such as TECH_SAILING or CIVIC_CRAFTSMANSHIP."),
	cost: z.number(),
	turns: z.number(),
	progress: z.number().optional().describe("There once it is above 0."),
	boost: BOOST.optional().describe("Left out for one with no boost."),
	unlocks: z.array(z.string()).optional().describe(
		"What it unlocks, by type, such as UNIT_GALLEY or POLICY_AGOGE. Left out when the game's unlocks file is missing.",
	),
	description: z.string().optional().describe(
		"The special unlock the chooser shows as a star, in the game's language. Left out for one without it.",
	),
	current: z.literal(true).optional().describe("True for the one in research. Left out otherwise."),
	recommended: z.literal(true).optional().describe(
		"True when the game's advisor recommends it. Left out otherwise.",
	),
	queue: z.number().optional().describe(
		"Its place in the research queue, from 1 for the one in research, as the chooser numbers it. Left out when it isn't queued.",
	),
});
