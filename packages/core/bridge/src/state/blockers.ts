// The schema for the blockers section of the state. The core mod builds it in
// Scripts/State/SentientSystemsCore_StateBlockers.lua.

import { z } from "zod";

export const BLOCKERS = z.object({
	list: z.array(z.object({
		type: z.string().describe("Such as ENDTURN_BLOCKING_RESEARCH."),
		choice: z.string().optional().describe(
			"The key in the choices that resolves the blocker, such as techs. It's left out for the unit blockers and for the values that no UI file names.",
		),
	})).describe(
		"Each end-turn blocker once, in the game's order. The first one is the Next Turn button's prompt.",
	),
	units: z.array(z.number()).describe(
		"The IDs of the player's units that need orders: those with moves left and no standing order, such as fortify. The list comes from the units, because the game updates its unit blockers only on its own events.",
	),
});
