// The schema for the spy choice: the escape routes for the player's next escaping spy, as the escape
// screen offers them. The game opens the same screen to choose a dragnet priority. The core mod
// builds it in Scripts/Choices/SentientSystemsCore_ChoicesSpies.lua.

import { z } from "zod";

// Left out of the choices with no escaping spy. The game offers one spy at a time, so it holds the
// next one: spy, its unit ID, name, city, the city it escapes from, loot, what it took, pursuer,
// who chases it, and description, the tooltip the open routes share, each in the game's language.
// Each route has type, the district it leaves by, such as DISTRICT_HARBOR, name, turns, and
// blocked, the screen's reason, when the city lacks the district.
export const SPIES_CHOICE = z.array(z.object({
	spy: z.number(),
	name: z.string(),
	city: z.object({ owner: z.number(), id: z.number(), name: z.string() }),
	loot: z.string(),
	pursuer: z.string(),
	description: z.string(),
	routes: z.array(z.object({
		type: z.string(),
		name: z.string(),
		turns: z.number(),
		blocked: z.array(z.string()).optional(),
	})),
})).optional();
