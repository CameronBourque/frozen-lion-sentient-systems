// The schema for the religion choices: the pantheon beliefs the player can found a pantheon with, as
// the pantheon chooser lists them. The core mod builds them in
// Scripts/Choices/SentientSystemsCore_ChoicesReligion.lua.

import { z } from "zod";

// Left out of the choices unless the player can found a pantheon now. beliefs lists the pantheon
// beliefs no player has taken, in the game's order, each with its description in the game's
// language.
export const PANTHEON = z.object({
	beliefs: z.array(z.object({ type: z.string(), description: z.string() })),
}).optional();
