// Reads one player's tech tree or civic tree from the core mod, as the tree
// screen shows it, so the agent can plan a route through the tree. The core mod
// builds it as JSON in a call of its own, in
// Scripts/Trees/SentientSystemsCore_TreesResearch.lua, and the bridge reads it
// through the stash, in stash.ts. The civic tree leaves out the screen's extra
// icons for envoys and governor titles.

import { z } from "zod";
import { readStash, type StashResult } from "../stash.js";
import type { TunerClient } from "../tuner/client.js";

// A node of the tree. A node the player hasn't revealed, in the Tech and Civic
// Shuffle mode, has a type such as "?1" and only era, status, turns, progress,
// and prerequisites, as the screen shows an Unrevealed box. The numbers follow
// the tree's order and link the hidden nodes within one read. The boost,
// unlocks, description, and recommended fields work as in the research choices,
// in ../choices/research.ts, and the screen shows no boost, progress, or
// advisor's pick for a researched node.
const NODE = z.object({
	type: z.string(),
	era: z.string(),
	status: z.enum(["researched", "current", "ready", "blocked"]),
	cost: z.number().optional().describe("Left out for an unrevealed node."),
	turns: z.number().optional().describe(
		"There while it is above 0 and the node isn't researched. For the node in research, it is the turns left.",
	),
	progress: z.number().optional().describe("There while it is above 0."),
	prerequisites: z.array(z.string()).describe(
		"By type, or by number such as ?1 for an unrevealed node, as the screen's lines link it.",
	),
	boost: z.object({ percent: z.number(), trigger: z.string(), triggered: z.boolean() }).optional(),
	unlocks: z.array(z.string()).optional(),
	description: z.string().optional(),
	recommended: z.literal(true).optional(),
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

// Reads the tech tree of the player with ID playerID. Every failure comes back
// as an error that says what went wrong, instead of an exception.
export function readTechTree(client: TunerClient, playerID: number): Promise<StashResult<Tree>> {
	return readStash(client, `SentientSystems_GetTechTree(${playerID})`, TREE, "tech tree");
}

// Reads the civic tree of the player with ID playerID, in the same form as the
// tech tree, with researched counting civics.
export function readCivicTree(client: TunerClient, playerID: number): Promise<StashResult<Tree>> {
	return readStash(client, `SentientSystems_GetCivicTree(${playerID})`, TREE, "civic tree");
}
