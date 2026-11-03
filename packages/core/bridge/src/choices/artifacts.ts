// The schema for the artifact choice: whose artifact the player's next digging archaeologist
// uncovers, as the artifact screen offers it. The core mod builds it in
// Scripts/Choices/SentientSystemsCore_ChoicesArtifacts.lua.

import { z } from "zod";

export const ARTIFACTS_CHOICE = z.array(z.object({
	archaeologist: z.number().describe("The archaeologist's unit ID."),
	name: z.string(),
	x: z.number(),
	y: z.number(),
	era: z.string().describe("The era the site is from, such as ERA_INDUSTRIAL."),
	description: z.string().describe("The screen's explanation, in the game's language."),
	options: z.array(z.object({
		player: z.number().describe("The ID the choice sends."),
		name: z.string(),
	})).describe(
		"The players whose artifact it can be: one for a tribal village, a barbarian camp, or a heroic relic, and two for a battle or a shipwreck.",
	),
})).optional().describe(
	"Left out of the choices with no archaeologist digging. The game offers one artifact at a time, so it holds the next one.",
);
