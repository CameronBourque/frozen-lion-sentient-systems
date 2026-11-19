// The schema for the events section of the state: what a popup the core mod
// closes would have told the player, and the moves it cancelled.

import { z } from "zod";

export const EVENTS = z.array(z.object({
	turn: z.number(),
	kind: z.enum(["unitLost", "unitCaptured", "concert", "moveCancelled"]).describe(
		"unitLost: another player captured a unit of the player's. unitCaptured: the player captured one. concert: a rock band of the player's performed. moveCancelled: no path reaches a unit's destination any more, so its move was cancelled.",
	),
	text: z.string().describe("The popup's text, or the core mod's for a cancelled move. A concert's has its result, tourism, albums sold, and whether the band gained a promotion or a level, or broke up."),
})).describe("From the previous turn and this one, oldest first. Lost when the game loads.");
