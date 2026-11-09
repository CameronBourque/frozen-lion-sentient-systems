// The schemas for the rivals section of the state. The core mod builds it in
// Scripts/State/SentientSystemsCore_StateRivals.lua.

import { z } from "zod";
import { POSITION } from "../schemas.js";
import { CITY_RELIGION, DEFENSE } from "./cities.js";
import { HEALTH } from "./units.js";

// City IDs repeat across players, so owner and id together name a city.
export const RIVAL_CITY = z.object({
	owner: z.number().describe("A player ID."),
	id: z.number(),
	name: z.string(),
	...POSITION.shape,
	population: z.number(),
	capital: z.boolean(),
	defense: DEFENSE,
	religion: CITY_RELIGION,
}).describe("A city on a tile the player has revealed, fogged or not, as its banner shows it.");

// Unit IDs repeat across players, so owner and id together name a unit.
export const RIVAL_UNIT = z.object({
	owner: z.number().describe("A player ID."),
	id: z.number(),
	type: z.string(),
	...POSITION.shape,
	health: HEALTH,
	religiousStrength: z.number().optional().describe("The strength that decides a religious attack. Left out for a unit that isn't religious."),
	religion: z.string().optional().describe(
		"The religion of a religious unit, such as RELIGION_SHINTO, as its flag shows it. Left out for any other unit. condemn_heretic needs it.",
	),
}).describe(
	"A unit on a tile that is visible now, as its flag shows it, and for which IsUnitVisible is true, which leaves out a stealthy unit on a visible tile. A unit on a fogged tile is never listed.",
);
