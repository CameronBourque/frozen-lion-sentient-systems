// The schema for the governor choice: the governors the player can appoint, the
// promotions they can give their governors, and the cities they can assign them
// to, as the Governors panel, its details panel, and its assignment chooser
// offer them. The core mod builds it in
// Scripts/Choices/SentientSystemsCore_ChoicesGovernors.lua. All text is in the
// game's language.

import { z } from "zod";

export const GOVERNORS_CHOICE = z.object({
	appoint: z.array(z.object({
		type: z.string().describe("Such as GOVERNOR_THE_DEFENDER."),
		name: z.string(),
		title: z.string(),
		description: z.string(),
		secret: z.literal(true).optional().describe(
			"True for a Secret Society the player has discovered, which has neither loyalty nor turns, as its card shows no stats.",
		),
		loyalty: z.number().optional().describe("The loyalty pressure on their card."),
		turnsToEstablish: z.number().optional().describe("The turns they take to settle in a city."),
	})).optional().describe(
		"The governors the player can appoint. There only with a title to spend.",
	),
	promote: z.array(z.object({
		governor: z.string().describe("The governor's type."),
		promotions: z.array(z.object({
			type: z.string(),
			name: z.string(),
			description: z.string(),
			hidden: z.literal(true).optional().describe(
				"True for a promotion the panel hides, with the game's own text in place of the name and description.",
			),
		})).describe("The promotions they can earn now."),
	})).optional().describe("Each appointed governor that can be promoted now. A Secret Society can be promoted."),
	assign: z.array(z.object({
		governor: z.string().describe("The governor's type."),
		cities: z.array(z.object({
			owner: z.number().describe("A player ID."),
			id: z.number(),
			name: z.string(),
			blocked: z.array(z.string()).optional().describe("The game's reasons, when the city can't take them."),
		})).describe(
			"Where they can go: the player's cities but the one they are in, then for an Ambassador the cities of the city-states met, then for a governor that can go abroad the capitals of the players met.",
		),
	})).optional().describe(
		"Each appointed governor that isn't neutralized, except a Secret Society, which has no Assign button.",
	),
}).optional().describe(
	"Left out of the choices without Rise and Fall, with nothing to do, and while Gathering Storm's World Congress is in session. Each key is left out with nothing to offer.",
);
