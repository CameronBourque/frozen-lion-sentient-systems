// The schema for the tiles section of the state. The core mod builds it in
// Scripts/State/SentientSystemsCore_StateTiles.lua.

import { z } from "zod";
import { POSITION } from "../schemas.js";

export const TILE = z.object({
	...POSITION.shape,
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
	tourism: z.number().optional().describe(
		"The tourism the tile gives each turn, as its banner shows on the tourism lens. Left out for a tile with none, and for a tile that isn't the player's own.",
	),
	tourists: z.number().optional().describe("The tourists visiting the tile. Left out when there are none, and when the tile has no tourism."),
	lifetime: z.number().optional().describe(
		"The tourism the tile has given in all, read from the end of the banner's tooltip. Left out when the tooltip has no such line.",
	),
	sources: z.array(z.string()).optional().describe(
		"What gives the tourism, one line each, in the game's language, from the banner's tooltip. Left out for a tile with no tourism.",
	),
	appeal: z.number().optional().describe(
		"The tile's appeal, as the tooltip and the appeal lens show it. 4 and above is breathtaking, 2 and above charming, -1 and above average, -3 and above uninviting, and below that disgusting. Left out when 0, and for water, except a natural wonder.",
	),
	continent: z.number().optional().describe(
		"The index of the tile's continent, which the continents section names. Left out for a tile with none, such as water.",
	),
	fallout: z.number().optional().describe(
		"The turns of nuclear fallout left on the tile, as the tooltip shows them. A unit that ends its turn there takes damage, and the tile can't be worked. Left out with none.",
	),
	visible: z.boolean().describe(
		"False for a tile under fog, which reads as it is now, as the game's tooltip shows it.",
	),
}).describe(
	"Values come from the live plot, as the tooltip shows them, not from the player's visibility layers, which the map's icons use.",
);
