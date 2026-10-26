// The schema for the purchase choice: what each of the player's cities can buy, by yield, as the
// production panel's purchase tabs list it. The core mod builds it in
// Scripts/Choices/SentientSystemsCore_ChoicesPurchases.lua.

import { z } from "zod";

// The reasons the panel greys an item out: the game's, then the panel's own text when the player
// can't afford it. Left out when the city can buy it. The list can be empty, when the game gives no
// reason.
const BLOCKED = z.array(z.string()).optional();

// A building, a district, or a unit trained as a corps or an army.
const PURCHASE = z.object({ cost: z.number(), blocked: BLOCKED });

const UNIT_PURCHASE = PURCHASE.extend({
	type: z.string(),
	// Each is left out when the city can't buy that formation.
	corps: PURCHASE.optional(),
	army: PURCHASE.optional(),
});

const TYPED_PURCHASE = PURCHASE.extend({ type: z.string() });

// What a city can buy with one yield. A district's tiles come from readPlacement, in
// src/placement/placement.ts.
const YIELD_PURCHASES = z.object({
	units: z.array(UNIT_PURCHASE),
	buildings: z.array(TYPED_PURCHASE),
	districts: z.array(TYPED_PURCHASE),
});

export const PURCHASE_CITY = z.object({
	city: z.number(),
	name: z.string(),
	gold: YIELD_PURCHASES,
});
