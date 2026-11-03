// The schema for the World Congress choice: what the player decides in a session of the World
// Congress, and looks at when one has ended, as the congress screen shows it. The core mod builds it
// in Scripts/Choices/SentientSystemsCore_ChoicesWorldCongress.lua. The results of a session's
// proposals aren't included.

import { z } from "zod";

const RESOLUTION = z.object({
	type: z.string().describe("Such as RESOLUTION_LUXURY_POLICY."),
	name: z.string(),
	options: z.object({ A: z.string(), B: z.string() }).describe("The text of each outcome."),
	targetType: z.string().describe("The kind of target, such as ResourceType or PlayerType."),
	targets: z.array(z.object({
		index: z.number().describe("The number a vote sends."),
		name: z.string(),
		player: z.number().optional().describe("The player's ID, for a player target."),
	})),
	favored: z.array(z.number()).describe("The player IDs the game says favor it."),
	disfavored: z.array(z.number()).describe("The player IDs the game says oppose it."),
});

const PROPOSAL = z.object({
	type: z.string().describe("Such as WC_EMERGENCY_BACKSTAB."),
	name: z.string(),
	description: z.string(),
	sender: z.number().describe("The proposing player's ID."),
	target: z.number().describe("The target player's ID."),
});

const AVAILABLE_PROPOSAL = z.object({
	type: z.string(),
	name: z.string(),
	description: z.string(),
	target: z.number(),
	cost: z.number().describe("In Favor."),
	disabled: z.boolean().describe("True for one the game won't take."),
});

const OUTCOME = z.object({
	name: z.string(),
	elected: z.string().describe("The label of the outcome, A or B."),
	text: z.string().describe("The outcome."),
	target: z.string().describe("A player's name or the game's text."),
	votes: z.object({ A: z.number(), B: z.number() }).optional().describe(
		"In the last session's results: the votes for each outcome.",
	),
	voters: z.array(z.object({
		player: z.number(),
		name: z.string(),
		option: z.enum(["A", "B"]),
		target: z.string().describe("What they chose it for."),
		votes: z.number(),
	})).optional().describe("In the last session's results: each player's vote."),
	turnsLeft: z.number().optional().describe("For a resolution in effect: the turns it has left."),
}).describe("A resolution that was decided.");

export const WORLD_CONGRESS_CHOICE = z.object({
	session: z.enum(["regular", "special", "review"]).optional().describe(
		"regular for a session with resolutions, special for one without, and review at the results blocker. There only while the session's blocker is up.",
	),
	favor: z.number().describe("The player's Diplomatic Favor."),
	voteCosts: z.array(z.number()).optional().describe(
		"In a session: the Favor for 1, 2, and so on up to the most votes, in total.",
	),
	resolutions: z.array(RESOLUTION).optional().describe("In a session: each with its outcomes in options."),
	proposals: z.array(PROPOSAL).optional().describe("In a session: the ones on the floor."),
	available: z.array(AVAILABLE_PROPOSAL).optional().describe(
		"Out of a session: the proposals the player could call a Special Session for. Left out with none.",
	),
	results: z.array(OUTCOME).optional().describe("At the results blocker: the last session's resolutions."),
	effects: z.array(OUTCOME).optional().describe("At the results blocker: the resolutions in effect."),
}).optional().describe("Left out of the choices with nothing to decide or look at.");
