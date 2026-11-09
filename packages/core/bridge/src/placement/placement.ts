// Reads where a city can place a district or wonder, with adjacency bonuses,
// as the placement view shows it, through the stash in stash.ts.

import { z } from "zod";
import { POSITION, YIELDS } from "../schemas.js";
import { readStash, type StashResult } from "../stash.js";
import type { TunerClient } from "../tuner/client.js";

// A tile where a district or a wonder can go.
const TILE = z.object({
	...POSITION.shape,
	adjacency: YIELDS.optional().describe(
		"A district's adjacency bonus on the tile, by yield, such as science 3, as the placement view shows it. Left out for a wonder, and for a tile with no bonus.",
	),
});

export const PLACEMENT = z.object({
	tiles: z.array(TILE).describe("The tiles the city owns where the district or wonder can go now."),
	purchaseTiles: z.array(TILE).describe(
		"The tiles the city could buy where it could go. It lists every tile to buy, while the panel counts a district's tile to buy only when it has a bonus. Neighborhood housing isn't included.",
	),
});

export type Placement = z.infer<typeof PLACEMENT>;

// A district's or a wonder's type, such as DISTRICT_CAMPUS. It goes into the
// Lua call as a string, so it must hold nothing that needs escaping.
const TYPE_NAME = /^[A-Z0-9_]+$/;

export async function readPlacement(client: TunerClient, playerID: number, cityID: number, typeName: string): Promise<StashResult<Placement>> {
	if (!TYPE_NAME.test(typeName)) {
		return { ok: false, error: `${JSON.stringify(typeName)} isn't a type name, such as DISTRICT_CAMPUS` };
	}

	return readStash(client, `SentientSystems_GetPlacement(${playerID}, ${cityID}, "${typeName}")`, PLACEMENT, "placement");
}
