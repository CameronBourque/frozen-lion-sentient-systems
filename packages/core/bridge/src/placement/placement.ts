// Reads where a city can place one district or wonder: the tiles it owns where it can go now, and
// the tiles it could buy where it could go, with each district's adjacency bonus on each tile, as
// the placement view shows them. The core mod builds them as JSON in
// Scripts/Placement/SentientSystemsCore_Placement.lua, and the bridge reads them through the stash,
// in stash.ts. docs/design/core/in-game-lua.md has the format.

import { z } from "zod";
import { readStash } from "../stash.js";
import type { TunerClient } from "../tuner/client.js";

// A tile where a district or a wonder can go.
const TILE = z.object({
	x: z.number(),
	y: z.number(),
	// A district's adjacency bonus on the tile, by yield, as the placement view shows it. Left out
	// for a wonder, and for a tile with no bonus.
	adjacency: z.object({
		food: z.number().optional(),
		production: z.number().optional(),
		gold: z.number().optional(),
		science: z.number().optional(),
		culture: z.number().optional(),
		faith: z.number().optional(),
	}).optional(),
});

const PLACEMENT = z.object({
	tiles: z.array(TILE),
	purchaseTiles: z.array(TILE),
});

export type Placement = z.infer<typeof PLACEMENT>;

export type PlacementResult =
	| { ok: true; placement: Placement; bytes: number }
	| { ok: false; error: string };

// A district's or a wonder's type, such as DISTRICT_CAMPUS. It goes into the Lua call as a string,
// so it must hold nothing that needs escaping.
const TYPE_NAME = /^[A-Z0-9_]+$/;

// Reads where the city with ID cityID, of the player with ID playerID, can place the district or
// wonder typeName. Every failure comes back as an error that says what went wrong, instead of an
// exception.
export async function readPlacement(client: TunerClient, playerID: number, cityID: number, typeName: string): Promise<PlacementResult> {
	if (!TYPE_NAME.test(typeName)) {
		return { ok: false, error: `${JSON.stringify(typeName)} isn't a type name, such as DISTRICT_CAMPUS` };
	}

	const result = await readStash(client, `SentientSystems_GetPlacement(${playerID}, ${cityID}, "${typeName}")`, PLACEMENT, "placement");

	return result.ok ? { ok: true, placement: result.value, bytes: result.bytes } : result;
}
