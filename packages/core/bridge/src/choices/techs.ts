// The schema for the tech choice: the techs the player can research now, as the research chooser
// lists them. The core mod builds it in Scripts/Choices/SentientSystemsCore_ChoicesTechs.lua.

import { z } from "zod";

export const TECH_OPTION = z.object({
	type: z.string(),
	cost: z.number(),
	turns: z.number(),
	// Left out until there is some.
	progress: z.number().optional(),
	// Left out for a tech with no boost. percent is the share of the cost that the boost gives.
	boost: z.object({ percent: z.number(), trigger: z.string(), triggered: z.boolean() }).optional(),
	// What the tech unlocks, by type, such as UNIT_GALLEY. Left out when the game's unlocks file is
	// missing.
	unlocks: z.array(z.string()).optional(),
	// What the chooser shows as a special unlock, a star, in the game's language. Left out for a tech
	// without one.
	description: z.string().optional(),
	// True for the tech in research. Left out otherwise.
	current: z.literal(true).optional(),
	// True when the game's advisor recommends the tech. Left out otherwise.
	recommended: z.literal(true).optional(),
});
