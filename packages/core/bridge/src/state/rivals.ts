// The schemas for the rivals section of the state. The core mod builds it in
// Scripts/State/SentientSystemsCore_StateRivals.lua.

import { z } from "zod";
import { DEFENSE } from "./cities.js";
import { HEALTH } from "./units.js";

// City IDs repeat across players, so owner and id together name a city.
export const RIVAL_CITY = z.object({
	owner: z.number().describe("A player ID."),
	id: z.number(),
	name: z.string(),
	x: z.number(),
	y: z.number(),
	population: z.number(),
	capital: z.boolean(),
	defense: DEFENSE,
}).describe("A city on a tile the player has revealed, fogged or not, as its banner shows it.");

// Unit IDs repeat across players, so owner and id together name a unit.
export const RIVAL_UNIT = z.object({
	owner: z.number().describe("A player ID."),
	id: z.number(),
	type: z.string(),
	x: z.number(),
	y: z.number(),
	health: HEALTH,
}).describe(
	"A unit on a tile that is visible now, as its flag shows it, and for which IsUnitVisible is true, which leaves out a stealthy unit on a visible tile. A unit on a fogged tile is never listed.",
);
