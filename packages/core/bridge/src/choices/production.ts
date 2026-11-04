// The schema for the production choice: what each of the player's cities can
// produce, as the production panel lists it. The core mod builds it in
// Scripts/Choices/SentientSystemsCore_ChoicesProduction.lua.

import { z } from "zod";

const BLOCKED = z.array(z.string()).optional().describe(
	"There when the panel greys the option out, with the game's reasons as the panel shows them, which can be none. Left out when the city can produce it.",
);

const FORMATION = z.object({ cost: z.number(), turns: z.number(), blocked: BLOCKED });

const PROGRESS = z.number().optional().describe("There once it is above 0.");

// The Heroes and Legends mode's panel isn't followed.
const UNIT_OPTION = z.object({
	type: z.string().describe("Such as UNIT_SETTLER."),
	cost: z.number(),
	turns: z.number(),
	progress: PROGRESS,
	blocked: BLOCKED,
	corps: FORMATION.optional().describe("There when the city can train the unit as a corps."),
	army: FORMATION.optional().describe("There when the city can train the unit as an army."),
});

const REPAIR = z.literal(true).optional().describe(
	"True when it is pillaged and producing it repairs it. Left out otherwise.",
);

// A building, wonders left out. The building in production is left out, as the
// panel leaves it out.
const BUILDING_OPTION = z.object({
	type: z.string().describe("Such as BUILDING_GRANARY."),
	district: z.string().optional().describe(
		"The district the panel lists the building under, such as DISTRICT_CITY_CENTER. Left out for a building without one.",
	),
	cost: z.number(),
	turns: z.number(),
	progress: PROGRESS,
	blocked: BLOCKED,
	repair: REPAIR,
});

// A district or a wonder. Its tiles come from readPlacement, in
// src/placement/placement.ts. A district with a tile only to buy isn't greyed
// out. Nuclear contamination isn't included.
const PLACED_OPTION = z.object({
	type: z.string().describe("Such as DISTRICT_CAMPUS or BUILDING_PYRAMIDS."),
	cost: z.number(),
	turns: z.number(),
	progress: PROGRESS,
	blocked: BLOCKED,
	repair: REPAIR,
});

const PROJECT_OPTION = z.object({
	type: z.string().describe("Such as PROJECT_ENHANCE_DISTRICT_CAMPUS."),
	cost: z.number(),
	turns: z.number(),
	progress: PROGRESS,
	blocked: BLOCKED,
	repeatable: z.literal(true).optional().describe(
		"True when the project can be produced more than once. Left out otherwise.",
	),
});

export const PRODUCTION_CITY = z.object({
	city: z.number().describe("The city's ID."),
	name: z.string().describe("In the game's language."),
	units: z.array(UNIT_OPTION),
	buildings: z.array(BUILDING_OPTION),
	districts: z.array(PLACED_OPTION).describe("Districts the panel shows as built are left out."),
	wonders: z.array(PLACED_OPTION),
	projects: z.array(PROJECT_OPTION),
});
