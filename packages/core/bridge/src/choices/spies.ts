// The schema for the spy choice: the escape routes for the player's next escaping spy, as the escape
// screen offers them. The game opens the same screen to choose a dragnet priority. The core mod
// builds it in Scripts/Choices/SentientSystemsCore_ChoicesSpies.lua. All text is in the game's
// language.

import { z } from "zod";

export const SPIES_CHOICE = z.array(z.object({
	spy: z.number().describe("The spy's unit ID."),
	name: z.string(),
	city: z.object({ owner: z.number(), id: z.number(), name: z.string() }).describe(
		"The city it escapes from.",
	),
	loot: z.string().describe("What it took."),
	pursuer: z.string().describe("Who chases it."),
	description: z.string().describe("The tooltip the open routes share."),
	routes: z.array(z.object({
		type: z.string().describe("The district it leaves by, such as DISTRICT_HARBOR."),
		name: z.string().describe("Such as Boat."),
		turns: z.number().optional(),
		blocked: z.array(z.string()).optional().describe(
			"In place of turns: the screen's reason, when the city lacks the district.",
		),
	})),
})).optional().describe(
	"Left out of the choices with no escaping spy. The game offers one spy at a time, so it holds the next one.",
);
