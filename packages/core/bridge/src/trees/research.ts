// Reads one player's tech or civic tree from the core mod, as the tree screen
// shows it, through the stash in stash.ts. The civic tree leaves out the
// screen's extra icons for envoys and governor titles.

import { z } from "zod";
import { readStash, type StashResult } from "../stash.js";
import type { TunerClient } from "../tuner/client.js";

// A node of the tree. In Tech and Civic Shuffle mode the screen shows a node
// the player hasn't revealed as an Unrevealed box, so it keeps only era,
// status, turns, progress, and prerequisites.
const NODE = z.object({
	type: z.string().describe(
		"An unrevealed node has a question mark and a number instead, in the tree's order. The numbers link the hidden nodes within one read.",
	),
	era: z.string(),
	status: z.enum(["researched", "current", "ready", "blocked"]),
	cost: z.number().optional().describe("Left out for an unrevealed node."),
	turns: z.number().optional().describe(
		"There while it is above 0 and the node isn't researched. For the node in research, it is the turns left.",
	),
	progress: z.number().optional().describe("There while it is above 0. Never on a researched node."),
	prerequisites: z.array(z.string()).describe(
		"By type, or by number such as ?1 for an unrevealed node, as the screen's lines link it.",
	),
	boost: z.object({ percent: z.number(), trigger: z.string(), triggered: z.boolean() }).optional().describe(
		"Left out for an unrevealed or researched node. Works as in ../choices/research.ts.",
	),
	unlocks: z.array(z.string()).optional().describe("Works as in ../choices/research.ts."),
	description: z.string().optional().describe("Works as in ../choices/research.ts."),
	recommended: z.literal(true).optional().describe("The advisor's pick. Never on a researched node."),
});

// The player or a player they have met, as the timeline at the bottom of the
// screen marks them.
const PLAYER = z.object({
	player: z.number(),
	researched: z.number().describe("The number of nodes they have researched."),
	era: z.string().optional().describe(
		"The latest era they have researched in. Left out when they have researched nothing.",
	),
});

// Not strict, so a field from a newer core mod is dropped instead of failing
// the whole tree.
export const TREE = z.object({
	nodes: z.array(NODE).describe("Every node of the tree, in the tree's order."),
	players: z.array(PLAYER),
});

export type Tree = z.infer<typeof TREE>;

export function readTechTree(client: TunerClient, playerID: number): Promise<StashResult<Tree>> {
	return readStash(client, `SentientSystems_GetTechTree(${playerID})`, TREE, "tech tree");
}

// Reads the civic tree of the player with ID playerID, in the same form as the
// tech tree, with researched counting civics.
export function readCivicTree(client: TunerClient, playerID: number): Promise<StashResult<Tree>> {
	return readStash(client, `SentientSystems_GetCivicTree(${playerID})`, TREE, "civic tree");
}
