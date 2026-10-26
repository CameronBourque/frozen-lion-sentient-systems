// The schema for the production choice: what each of the player's cities can produce, as the
// production panel lists it. The core mod builds it in
// Scripts/Choices/SentientSystemsCore_ChoicesProduction.lua.

import { z } from "zod";

// The game's reasons that the panel greys an option out. Left out when the city can produce it.
// The list can be empty, when the game gives no reason.
const BLOCKED = z.array(z.string()).optional();

// A unit trained as a corps or an army.
const FORMATION = z.object({ cost: z.number(), turns: z.number(), blocked: BLOCKED });

const UNIT_OPTION = z.object({
	type: z.string(),
	cost: z.number(),
	turns: z.number(),
	// Left out until there is some.
	progress: z.number().optional(),
	blocked: BLOCKED,
	// Each is left out when the city can't train that formation.
	corps: FORMATION.optional(),
	army: FORMATION.optional(),
});

// A building, wonders left out.
const BUILDING_OPTION = z.object({
	type: z.string(),
	// The district the panel lists the building under, such as DISTRICT_CITY_CENTER. Left out for a
	// building without one.
	district: z.string().optional(),
	cost: z.number(),
	turns: z.number(),
	progress: z.number().optional(),
	blocked: BLOCKED,
	// True when the building is pillaged and producing it repairs it. Left out otherwise.
	repair: z.literal(true).optional(),
});

export const PRODUCTION_CITY = z.object({
	city: z.number(),
	name: z.string(),
	units: z.array(UNIT_OPTION),
	buildings: z.array(BUILDING_OPTION),
});
