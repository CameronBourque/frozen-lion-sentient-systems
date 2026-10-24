// The schemas for the rivals section of the state: other players' cities and units that the player
// can know about, as their city banners and unit flags show them. The core mod builds it in
// Scripts/State/SentientSystemsCore_StateRivals.lua.

import { z } from "zod";
import { HEALTH } from "./units.js";

export const RIVAL_CITY = z.object({
	owner: z.number(),
	id: z.number(),
	name: z.string(),
	x: z.number(),
	y: z.number(),
	population: z.number(),
	capital: z.boolean(),
	// walls is left out for a city with none.
	defense: z.object({ strength: z.number(), garrison: HEALTH, walls: HEALTH.optional() }),
});

export const RIVAL_UNIT = z.object({
	owner: z.number(),
	id: z.number(),
	type: z.string(),
	x: z.number(),
	y: z.number(),
	health: HEALTH,
});
