// The schema for the tech and civic choices: the techs and civics the player can research now, as
// the research and civics choosers list them. The core mod builds them in
// Scripts/Choices/SentientSystemsCore_ChoicesResearch.lua.

import { z } from "zod";

export const RESEARCH_OPTION = z.object({
	type: z.string(),
	cost: z.number(),
	turns: z.number(),
	// Left out until there is some.
	progress: z.number().optional(),
	// Left out for one with no boost. percent is the share of the cost that the boost gives.
	boost: z.object({ percent: z.number(), trigger: z.string(), triggered: z.boolean() }).optional(),
	// What it unlocks, by type, such as UNIT_GALLEY or POLICY_AGOGE. Left out when the game's unlocks file is
	// missing.
	unlocks: z.array(z.string()).optional(),
	// What the chooser shows as a special unlock, a star, in the game's language. Left out for one
	// without it.
	description: z.string().optional(),
	// True for the one in research. Left out otherwise.
	current: z.literal(true).optional(),
	// True when the game's advisor recommends it. Left out otherwise.
	recommended: z.literal(true).optional(),
});
