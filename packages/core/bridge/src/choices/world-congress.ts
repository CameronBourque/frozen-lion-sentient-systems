// The schema for the World Congress choice: what the player decides in a session of the World
// Congress, and looks at when one has ended, as the congress screen shows it. The core mod builds it
// in Scripts/Choices/SentientSystemsCore_ChoicesWorldCongress.lua.

import { z } from "zod";

const RESOLUTION = z.object({
	type: z.string(),
	name: z.string(),
	options: z.object({ A: z.string(), B: z.string() }),
	targetType: z.string(),
	targets: z.array(z.object({ index: z.number(), name: z.string(), player: z.number().optional() })),
	favored: z.array(z.number()),
	disfavored: z.array(z.number()),
});

const PROPOSAL = z.object({
	type: z.string(),
	name: z.string(),
	description: z.string(),
	sender: z.number(),
	target: z.number(),
});

const AVAILABLE_PROPOSAL = z.object({
	type: z.string(),
	name: z.string(),
	description: z.string(),
	target: z.number(),
	cost: z.number(),
	disabled: z.boolean(),
});

// A resolution that was decided: elected, the label of the outcome, A or B, text, the outcome, and
// target, a player's name or the game's text. In the last session's results, votes holds the votes for
// each outcome, and voters each player's vote, with player, name, option, A or B, target, what they
// chose it for, and votes. turnsLeft is the turns a resolution in effect has left.
const OUTCOME = z.object({
	name: z.string(),
	elected: z.string(),
	text: z.string(),
	target: z.string(),
	votes: z.object({ A: z.number(), B: z.number() }).optional(),
	voters: z.array(z.object({ player: z.number(), name: z.string(), option: z.enum(["A", "B"]), target: z.string(), votes: z.number() })).optional(),
	turnsLeft: z.number().optional(),
});

// Left out of the choices with nothing to decide or look at. favor is the player's Diplomatic Favor.
// In a session, session is regular for one with resolutions, and special for one without, with
// voteCosts, the Favor for 1, 2, and so on up to the most votes, in total, resolutions, each with its
// outcomes in options, and its targets, where index is the number a vote sends, and proposals, the
// ones on the floor. Out of a session, available lists the proposals the player could call a Special
// Session for, and at the results blocker session is review, with results and effects.
export const WORLD_CONGRESS_CHOICE = z.object({
	session: z.enum(["regular", "special", "review"]).optional(),
	favor: z.number(),
	voteCosts: z.array(z.number()).optional(),
	resolutions: z.array(RESOLUTION).optional(),
	proposals: z.array(PROPOSAL).optional(),
	available: z.array(AVAILABLE_PROPOSAL).optional(),
	results: z.array(OUTCOME).optional(),
	effects: z.array(OUTCOME).optional(),
}).optional();
