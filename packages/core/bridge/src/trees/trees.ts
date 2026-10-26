// Reads one player's tech tree from the core mod, as the tech tree screen shows it, so the agent can
// plan a route through the tree. The core mod builds it as JSON in a call of its own, in
// Scripts/Trees/SentientSystemsCore_Trees.lua, and the bridge reads it through the stash, in
// stash.ts. docs/design/core/in-game-lua.md has the format.

import { z } from "zod";
import { readStash } from "../stash.js";
import type { TunerClient } from "../tuner/client.js";

// A node of the tree. A node the player hasn't revealed, in the Tech and Civic Shuffle mode, has a
// type such as "?1" and only era, status, turns, progress, and prerequisites, as the screen shows
// an Unrevealed box. The numbers link the hidden nodes within one read.
const NODE = z.object({
	type: z.string(),
	era: z.string(),
	status: z.enum(["researched", "current", "ready", "blocked"]),
	// Left out for an unrevealed node.
	cost: z.number().optional(),
	// Left out for a researched node, and while they aren't above 0.
	turns: z.number().optional(),
	progress: z.number().optional(),
	// By type, or "?1" and so on for an unrevealed node.
	prerequisites: z.array(z.string()),
	boost: z.object({ percent: z.number(), trigger: z.string(), triggered: z.boolean() }).optional(),
	unlocks: z.array(z.string()).optional(),
	description: z.string().optional(),
	recommended: z.literal(true).optional(),
});

// The player or a player they have met, as the timeline marks them.
const PLAYER = z.object({
	player: z.number(),
	researched: z.number(),
	// The latest era they have researched in. Left out when they have researched nothing.
	era: z.string().optional(),
});

// Not strict, so a field from a newer core mod is dropped instead of failing the whole tree.
const TREE = z.object({
	nodes: z.array(NODE),
	players: z.array(PLAYER),
});

export type Tree = z.infer<typeof TREE>;

export type TreeResult =
	| { ok: true; tree: Tree; bytes: number }
	| { ok: false; error: string };

// Reads the tech tree of the player with ID playerID. Every failure comes back as an error that says
// what went wrong, instead of an exception.
export async function readTechTree(client: TunerClient, playerID: number): Promise<TreeResult> {
	const result = await readStash(client, `SentientSystems_GetTechTree(${playerID})`, TREE, "tech tree");

	return result.ok ? { ok: true, tree: result.value, bytes: result.bytes } : result;
}
