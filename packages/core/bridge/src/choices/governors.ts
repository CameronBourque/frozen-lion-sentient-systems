// The schema for the governor choice: the governors the player can appoint, the promotions they can
// give their governors, and the cities they can assign them to, as the Governors panel, its details
// panel, and its assignment chooser offer them. The core mod builds it in
// Scripts/Choices/SentientSystemsCore_ChoicesGovernors.lua.

import { z } from "zod";

// Left out of the choices without Rise and Fall, with nothing to do, and while Gathering Storm's
// World Congress is in session. Each key is left out with nothing to offer. All text is in the game's
// language.
export const GOVERNORS_CHOICE = z.object({
	// The governors the player can appoint, there only with a title to spend. Each has type, such as
	// GOVERNOR_THE_DEFENDER, name, title, description, loyalty, the loyalty pressure on their card, and
	// turnsToEstablish, the turns they take to settle in a city.
	appoint: z.array(z.object({
		type: z.string(),
		name: z.string(),
		title: z.string(),
		description: z.string(),
		loyalty: z.number(),
		turnsToEstablish: z.number(),
	})).optional(),
	// Each appointed governor that can be promoted now, with governor, its type, and promotions, the
	// ones they can earn now, each with type, name, and description.
	promote: z.array(z.object({
		governor: z.string(),
		promotions: z.array(z.object({ type: z.string(), name: z.string(), description: z.string() })),
	})).optional(),
	// Each appointed governor that isn't neutralized, with governor and cities, the places they can go:
	// the player's cities but the one they are in, then the cities of the city-states met for an
	// Ambassador, then the capitals of the players met for a governor that can go abroad. A city has
	// owner, a player ID, id, and name, and blocked, the game's reasons, when it can't take them.
	assign: z.array(z.object({
		governor: z.string(),
		cities: z.array(z.object({
			owner: z.number(),
			id: z.number(),
			name: z.string(),
			blocked: z.array(z.string()).optional(),
		})),
	})).optional(),
}).optional();
