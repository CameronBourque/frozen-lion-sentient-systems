// Reads one player's governor tree from the core mod, as the Governors panel shows it, so the agent
// can choose a governor to appoint and a promotion to give. The core mod builds it as JSON in a call
// of its own, in Scripts/Trees/SentientSystemsCore_TreesGovernors.lua, and the bridge reads it through
// the stash, in stash.ts. docs/design/core/in-game-lua.md has the format.

import { z } from "zod";
import { readStash } from "../stash.js";
import type { TunerClient } from "../tuner/client.js";

// A promotion in a governor's tree: type, name, description, level and column, its place in the
// tree, and requires, the types of the promotions it follows, any one of which it needs, empty for
// the base ability. status is held, for one the governor has, available, for one they can earn now,
// and locked, for one that needs a prerequisite first. A candidate holds only its base ability.
// hidden is true for a promotion of a Secret Society that the panel hides until the one before it is
// held, and its name and description are then the game's own text for an unknown promotion.
const GOVERNOR_PROMOTION = z.object({
	type: z.string(),
	name: z.string(),
	description: z.string(),
	level: z.number(),
	column: z.number(),
	requires: z.array(z.string()),
	status: z.enum(["held", "available", "locked"]),
	hidden: z.literal(true).optional(),
});

// A governor with their tree: appointed governors first in the panel's order, then the governors the
// player could still appoint, which includes the Secret Societies they have discovered. A society
// has secret, true, and neither turnsToEstablish, the turns a governor takes to settle in a city, nor
// loyalty, the loyalty pressure they give, as its card shows no stats.
const GOVERNOR = z.object({
	type: z.string(),
	name: z.string(),
	title: z.string(),
	description: z.string(),
	status: z.enum(["appointed", "candidate"]),
	secret: z.literal(true).optional(),
	turnsToEstablish: z.number().optional(),
	loyalty: z.number().optional(),
	promotions: z.array(GOVERNOR_PROMOTION),
});

// Empty without Rise and Fall.
const GOVERNOR_TREE = z.object({ governors: z.array(GOVERNOR) });

export type GovernorTree = z.infer<typeof GOVERNOR_TREE>;

export type GovernorTreeResult =
	| { ok: true; tree: GovernorTree; bytes: number }
	| { ok: false; error: string };

// Reads the governor tree of the player with ID playerID.
export async function readGovernorTree(client: TunerClient, playerID: number): Promise<GovernorTreeResult> {
	const result = await readStash(client, `SentientSystems_GetGovernorTree(${playerID})`, GOVERNOR_TREE, "governor tree");

	return result.ok ? { ok: true, tree: result.value, bytes: result.bytes } : result;
}
