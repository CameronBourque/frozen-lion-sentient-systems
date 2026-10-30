// The schema for the blockers section of the state: what stops the end of the turn, and the units
// that need orders. The core mod builds it in Scripts/State/SentientSystemsCore_StateBlockers.lua.

import { z } from "zod";

export const BLOCKERS = z.object({
	// Each blocker once, in the game's order. The first one is the Next Turn button's prompt.
	list: z.array(z.object({
		// Such as ENDTURN_BLOCKING_RESEARCH.
		type: z.string(),
		// The key in the choices that resolves the blocker, such as techs. It's left out for the unit
		// blockers and for the values that no UI file names.
		choice: z.string().optional(),
	})),
	// The IDs of the player's units that need orders.
	units: z.array(z.number()),
});
