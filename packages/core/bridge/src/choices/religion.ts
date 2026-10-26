// The schemas for the religion choices: the pantheon beliefs the player can found a pantheon with, as
// the pantheon chooser lists them, and the religions and beliefs the player can found a religion with
// or add to it, as the religion screen lists them. The core mod builds them in
// Scripts/Choices/SentientSystemsCore_ChoicesReligion.lua.

import { z } from "zod";

// Left out of the choices unless the player can found a pantheon now. beliefs lists the pantheon
// beliefs no player has taken, in the game's order, each with its description in the game's
// language.
export const PANTHEON = z.object({
	beliefs: z.array(z.object({ type: z.string(), description: z.string() })),
}).optional();

// Left out of the choices unless the religion screen offers a religion or beliefs: after the
// pantheon, with more beliefs earned than the religion has. religions lists the religions no player
// has founded, there only before the player founds one, and customName is true for one the player
// must name. picks is the number of beliefs to choose now: at most one of each class, and a follower
// belief first for a new religion. beliefs lists those on offer, ordered by class as the screen
// orders them, each with its class, such as BELIEF_CLASS_FOLLOWER, and its description in the game's
// language.
export const RELIGION_CHOICE = z.object({
	religions: z.array(z.object({ type: z.string(), customName: z.literal(true).optional() })).optional(),
	picks: z.number(),
	beliefs: z.array(z.object({ type: z.string(), class: z.string(), description: z.string() })),
}).optional();
