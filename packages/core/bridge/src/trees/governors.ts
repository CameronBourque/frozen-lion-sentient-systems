// Reads one player's governor tree from the core mod, as the Governors panel
// shows it, so the agent can choose a governor to appoint and a promotion to
// give. The core mod builds it as JSON in a call of its own, in
// Scripts/Trees/SentientSystemsCore_TreesGovernors.lua, and the bridge reads it
// through the stash, in stash.ts.

import { z } from "zod";
import { readStash, type StashResult } from "../stash.js";
import type { TunerClient } from "../tuner/client.js";

// A promotion in a governor's tree. A candidate holds only its base ability.
const GOVERNOR_PROMOTION = z.object({
	type: z.string().describe(
		"For a hidden promotion it is numbered, such as GOVERNOR_PROMOTION_OWLS_OF_MINERVA_2, and gives nothing away.",
	),
	name: z.string(),
	description: z.string(),
	level: z.number().describe("Its place in the tree, with column. The base ability is level 0."),
	column: z.number(),
	requires: z.array(z.string()).describe(
		"The types of the promotions it follows. It needs any one of them, not all of them. Empty for the base ability.",
	),
	status: z.enum(["held", "available", "locked"]).describe(
		"held for one the governor has, available for one they can earn now, and locked for one that needs a prerequisite first.",
	),
	hidden: z.literal(true).optional().describe(
		"True for a promotion of a Secret Society that the panel hides until the one before it is held. Its name and description are then the game's own text for an unknown promotion, ???.",
	),
});

// A governor with their tree.
const GOVERNOR = z.object({
	type: z.string().describe("Such as GOVERNOR_THE_MERCHANT."),
	name: z.string(),
	title: z.string(),
	description: z.string(),
	status: z.enum(["appointed", "candidate"]),
	secret: z.literal(true).optional().describe(
		"True for a Secret Society, which has neither turnsToEstablish nor loyalty, as its card shows no stats.",
	),
	turnsToEstablish: z.number().optional().describe("The turns they take to settle in a city."),
	loyalty: z.number().optional().describe("The loyalty pressure they give."),
	promotions: z.array(GOVERNOR_PROMOTION).describe("In the game's order."),
});

export const GOVERNOR_TREE = z.object({
	governors: z.array(GOVERNOR).describe(
		"Each appointed governor in the panel's order, then each governor the player could still appoint, which includes the Secret Societies they have discovered. Empty without Rise and Fall.",
	),
});

export type GovernorTree = z.infer<typeof GOVERNOR_TREE>;

// Reads the governor tree of the player with ID playerID.
export function readGovernorTree(client: TunerClient, playerID: number): Promise<StashResult<GovernorTree>> {
	return readStash(client, `SentientSystems_GetGovernorTree(${playerID})`, GOVERNOR_TREE, "governor tree");
}
