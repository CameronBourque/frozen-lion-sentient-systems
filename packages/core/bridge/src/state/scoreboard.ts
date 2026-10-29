// The schema for the scoreboard section of the state: each living major player's score, as the Score
// tab of World Rankings shows it, and the leader panel's numbers for the player and each player they
// have met. Format: docs/design/core/in-game-lua.md.

import { z } from "zod";

export const SCOREBOARD = z.array(z.object({
	// Left out for a player the player has not met, as the tab hides who they are.
	player: z.number().optional(),
	score: z.number(),
	// What the score is made of, in the game's order, as the tab's details show it. name is in the
	// game's language.
	categories: z.array(z.object({ type: z.string(), name: z.string(), score: z.number() })),
	// The leader panel's numbers, left out for a player the player has not met.
	military: z.number().optional(),
	// Per turn.
	science: z.number().optional(),
	culture: z.number().optional(),
	// The balances.
	gold: z.number().optional(),
	faith: z.number().optional(),
	// Left out without Gathering Storm, and when the diplomatic victory is off.
	favor: z.number().optional(),
}));
