// Schemas that several sections of the state, the choices, and the placement
// share.

import { z } from "zod";

// A city named by its owner and ID, as the actions take it.
export const CITY_ID = z.object({ owner: z.number(), id: z.number() });

// A city named by its owner and ID, with its name.
export const CITY_REF = CITY_ID.extend({ name: z.string().describe("In the game's language.") });

// A tile's position. A schema spreads its shape, so x and y stay flat in the
// JSON.
export const POSITION = z.object({ x: z.number(), y: z.number() });

export type Position = z.infer<typeof POSITION>;

// A tech's or a civic's boost, as the research choice and the tree show it.
export const BOOST = z.object({
	percent: z.number().describe("The share of the cost that the boost gives."),
	trigger: z.string().describe("The trigger's text, in the game's language."),
	triggered: z.boolean(),
});

// An amount of each of the six yields. A yield can be left out.
export const YIELDS = z.object({
	food: z.number().optional(),
	production: z.number().optional(),
	gold: z.number().optional(),
	science: z.number().optional(),
	culture: z.number().optional(),
	faith: z.number().optional(),
});
