// The schema for the artifact choice: whose artifact the player's next digging archaeologist
// uncovers, as the artifact screen offers it. The core mod builds it in
// Scripts/Choices/SentientSystemsCore_ChoicesArtifacts.lua.

import { z } from "zod";

// Left out of the choices with no archaeologist digging. The game offers one artifact at a time, so
// it holds the next one: archaeologist, its unit ID, name, x, y, era, the era the site is from, such
// as ERA_INDUSTRIAL, and description, the screen's explanation in the game's language. options lists
// the players whose artifact it can be, each with player, the ID the choice sends, and name: one for
// a tribal village, a barbarian camp, or a heroic relic, and two for a battle or a shipwreck.
export const ARTIFACTS_CHOICE = z.array(z.object({
	archaeologist: z.number(),
	name: z.string(),
	x: z.number(),
	y: z.number(),
	era: z.string(),
	description: z.string(),
	options: z.array(z.object({ player: z.number(), name: z.string() })),
})).optional();
