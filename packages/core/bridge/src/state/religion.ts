// The schema for the religion section of the state: the player's pantheon, their progress toward a
// religion, and the religion they founded with its followers, as the religion screen's My Religion
// tab shows them. The core mod builds it in Scripts/State/SentientSystemsCore_StateReligion.lua.

import { z } from "zod";

export const RELIGION = z.object({
	// The player's pantheon belief, such as BELIEF_GOD_OF_THE_SEA. Left out before they have one.
	pantheon: z.string().optional(),
	// The faith the next pantheon needs. There only before the player has a pantheon.
	pantheonFaith: z.number().optional(),
	// Whether the player has a Great Prophet. There only between their pantheon and their first
	// belief.
	prophet: z.boolean().optional(),
	// The religion the player founded. Left out before they found one. holyCity is a city ID, left
	// out once no city holds it. majority counts the cities where it is the majority religion, and
	// cities lists each city of any player with followers of it.
	founded: z.object({
		type: z.string(),
		name: z.string(),
		beliefs: z.array(z.string()),
		holyCity: z.number().optional(),
		majority: z.number(),
		cities: z.array(z.object({ owner: z.number(), city: z.number(), followers: z.number() })),
	}).optional(),
});
