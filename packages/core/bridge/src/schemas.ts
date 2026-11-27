// Schemas and types that several sections of the state, the choices, the
// placement, and the actions share.

import { z } from "zod";

// A city named by its owner and ID, as the actions take it.
export const CITY_ID = z.object({ owner: z.number(), id: z.number() });

// A city named by its owner and ID, with its name.
export const CITY_REF = CITY_ID.extend({ name: z.string().describe("In the game's language.") });

// One of the player's own cities, by ID and name. It has no owner, because the
// player is the owner.
export const OWN_CITY_REF = CITY_REF.omit({ owner: true });

// A great work slot, by its city, building, and index, as the great works
// state and the great work moves name it.
export const GREAT_WORK_SLOT_REF = z.object({
	city: OWN_CITY_REF,
	building: z.string().describe("The type of the building that holds the slot."),
	slot: z.number().describe("The slot's index in its building."),
});

// A tile's position. A schema spreads its shape, so x and y stay flat in the
// JSON.
export const POSITION = z.object({ x: z.number(), y: z.number() });

export type Position = z.infer<typeof POSITION>;

// A World Congress resolution's two options, by the letter the choice and the
// vote action name them by. SENTIENTSYSTEMS_RESOLUTION_OPTIONS in
// Scripts/SentientSystemsCore_WorldCongress.lua lists the same two.
export const RESOLUTION_OPTION = z.enum(["A", "B"]);

export type ResolutionOption = z.infer<typeof RESOLUTION_OPTION>;

// A yield the player spends to buy a unit, a building, or a great person, by
// its key in the purchases choice and the great people state.
export type PurchaseYield = "gold" | "faith";

// A tech's or a civic's boost, as the research choice and the tree show it.
export const BOOST = z.object({
	percent: z.number().describe("The share of the cost that the boost gives."),
	trigger: z.string().describe("The trigger's text, in the game's language."),
	triggered: z.boolean(),
});

// A tech or a civic as the research choosers and the tree screens show it. The
// core mod builds both with reader.Option in
// Scripts/Choices/SentientSystemsCore_ChoicesResearch.lua.
export const RESEARCH_ITEM = z.object({
	type: z.string().describe("Such as TECH_SAILING or CIVIC_CRAFTSMANSHIP."),
	cost: z.number(),
	turns: z.number(),
	progress: z.number().optional().describe("There once it is above 0."),
	boost: BOOST.optional().describe("Left out for one with no boost."),
	unlocks: z.array(z.string()).optional().describe(
		"What it unlocks, by type, such as UNIT_GALLEY or POLICY_AGOGE. Left out when the game's unlocks file is missing.",
	),
	description: z.string().optional().describe(
		"The special unlock the screen shows as a star, in the game's language. Left out for one without it.",
	),
	recommended: z.literal(true).optional().describe(
		"True when the game's advisor recommends it. Left out otherwise.",
	),
	queue: z.number().optional().describe(
		"Its place in the research queue, from 1 for the one in research, as the chooser and the tree screen number it. Left out when it isn't queued.",
	),
});

// An amount of one yield, for a list that names each yield it holds.
export const YIELD_AMOUNT = z.object({ type: z.string().describe("A yield type, such as YIELD_CULTURE."), amount: z.number() });

// An amount of each of the six yields. A yield can be left out.
export const YIELDS = z.object({
	food: z.number().optional(),
	production: z.number().optional(),
	gold: z.number().optional(),
	science: z.number().optional(),
	culture: z.number().optional(),
	faith: z.number().optional(),
});

// The end-turn blockers, as the state's blockers section and a forced end
// turn list them. The core mod builds them in
// Scripts/State/SentientSystemsCore_StateBlockers.lua.
export const BLOCKERS = z.object({
	list: z.array(z.object({
		type: z.string().describe("Such as ENDTURN_BLOCKING_RESEARCH."),
		choice: z.string().optional().describe(
			"The key in the choices that resolves the blocker, such as techs. It's left out for the unit blockers and for the values that no UI file names.",
		),
	})).describe(
		"Each end-turn blocker once, in the game's order. The first one is the Next Turn button's prompt.",
	),
	units: z.array(z.number()).describe(
		"The IDs of the player's units that need orders: those with moves left and no standing order, such as fortify. The list comes from the units, because the game updates its unit blockers only on its own events.",
	),
});
