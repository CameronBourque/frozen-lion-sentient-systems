// The schema for the tiles section of the state: each tile the player has revealed, as the tooltip
// shows it. The core mod builds it in Scripts/State/SentientSystemsCore_StateTiles.lua.

import { z } from "zod";

export const TILE = z.object({
	x: z.number(),
	y: z.number(),
	terrain: z.string(),
	feature: z.string().optional(),
	resource: z.string().optional(),
	owner: z.number().optional(),
	district: z.string().optional(),
	improvement: z.string().optional(),
	// The core mod sends these two only when they are true.
	improvementPillaged: z.literal(true).optional(),
	route: z.string().optional(),
	routePillaged: z.literal(true).optional(),
	visible: z.boolean(),
});
