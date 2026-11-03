// The schemas for the religion choices: the pantheon beliefs the player can
// found a pantheon with, as the pantheon chooser lists them, and the religions
// and beliefs the player can found a religion with or add to it, as the
// religion screen lists them. The core mod builds them in
// Scripts/Choices/SentientSystemsCore_ChoicesReligion.lua.

import { z } from "zod";

export const PANTHEON = z.object({
	beliefs: z.array(z.object({
		type: z.string().describe("Such as BELIEF_GOD_OF_THE_SEA."),
		description: z.string().describe("In the game's language."),
	})).describe("The pantheon beliefs no player has taken, in the game's order."),
}).optional().describe("Left out of the choices unless the player can found a pantheon now.");

export const RELIGION_CHOICE = z.object({
	religions: z.array(z.object({
		type: z.string().describe("Such as RELIGION_BUDDHISM."),
		customName: z.literal(true).optional().describe("True for one the player must name."),
	})).optional().describe(
		"The religions no player has founded. There only before the player founds one.",
	),
	picks: z.number().describe(
		"The number of beliefs to choose now: at most one of each class, and a follower belief first for a new religion.",
	),
	beliefs: z.array(z.object({
		type: z.string(),
		class: z.string().describe("Such as BELIEF_CLASS_FOLLOWER."),
		description: z.string().describe("In the game's language."),
	})).describe(
		"The beliefs on offer, sorted by class as the screen sorts them. The order within a class means nothing, as the screen's own order within a class is left to chance.",
	),
}).optional().describe(
	"Left out of the choices unless the religion screen offers a religion or beliefs: after the pantheon, with more beliefs earned than the religion has.",
);
