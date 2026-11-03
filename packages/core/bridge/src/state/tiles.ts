// The schema for the tiles section of the state. The core mod builds it in
// Scripts/State/SentientSystemsCore_StateTiles.lua.

import { z } from "zod";

export const TILE = z.object({
	x: z.number(),
	y: z.number(),
	terrain: z.string().describe("Such as TERRAIN_GRASS_HILLS."),
	feature: z.string().optional().describe("Such as FEATURE_FOREST. Left out for a tile with none."),
	resource: z.string().optional().describe(
		"Such as RESOURCE_IRON. Left out for a tile with none, and for a resource that the player's techs don't reveal yet, as the tooltip leaves it out.",
	),
	owner: z.number().optional().describe("A player ID. Left out for a tile with none."),
	district: z.string().optional().describe("Left out for a tile with none."),
	improvement: z.string().optional().describe("Left out for a tile with none."),
	improvementPillaged: z.literal(true).optional().describe("There only when true."),
	route: z.string().optional().describe(
		"Such as ROUTE_ANCIENT_ROAD. Left out for a tile with none.",
	),
	routePillaged: z.literal(true).optional().describe("There only when true."),
	visible: z.boolean().describe(
		"False for a tile under fog, which reads as it is now, as the game's tooltip shows it.",
	),
}).describe(
	"Values come from the live plot, as the tooltip shows them, not from the player's visibility layers, which the map's icons use.",
);
