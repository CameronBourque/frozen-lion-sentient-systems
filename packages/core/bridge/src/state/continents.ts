// The schema for one continent of the state, as the continents lens key lists
// it. The core mod builds the list in
// Scripts/State/SentientSystemsCore_StateContinents.lua.

import { z } from "zod";

export const CONTINENT = z.object({
	index: z.number().describe("The index that a tile's continent holds."),
	type: z.string().describe("Such as CONTINENT_PANGAEA."),
	name: z.string().describe("In the game's language."),
});
