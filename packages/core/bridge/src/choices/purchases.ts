// The schema for the purchase choice: what each of the player's cities can buy,
// by yield, as the production panel's purchase tabs list it. The core mod
// builds it in Scripts/Choices/SentientSystemsCore_ChoicesPurchases.lua.

import { z } from "zod";

const BLOCKED = z.array(z.string()).optional().describe(
	"There when the tab greys the item out: the game's reasons, then the tab's own text when the player can't afford it, such as Not enough Gold in treasury to purchase this. Can be empty, when the game gives no reason. Left out when the city can buy it.",
);

// A building, a district, or a unit trained as a corps or an army. cost is in
// the yield.
const PURCHASE = z.object({ cost: z.number(), blocked: BLOCKED });

const UNIT_PURCHASE = PURCHASE.extend({
	type: z.string(),
	corps: PURCHASE.optional().describe("There when the city can buy the unit as a corps."),
	army: PURCHASE.optional().describe("There when the city can buy the unit as an army."),
});

const TYPED_PURCHASE = PURCHASE.extend({ type: z.string() });

// What a city can buy with one yield. A district's tiles come from
// readPlacement, in src/placement/placement.ts.
const YIELD_PURCHASES = z.object({
	units: z.array(UNIT_PURCHASE),
	buildings: z.array(TYPED_PURCHASE),
	districts: z.array(TYPED_PURCHASE),
});

const TILE_PURCHASE = PURCHASE.extend({ x: z.number(), y: z.number() }).describe(
	"blocked is there when the cost is more than the player's gold, with the purchase lens's tooltip, such as You need 18 more Gold in order to purchase this plot.",
);

export const PURCHASE_CITY = z.object({
	city: z.number().describe("The city's ID."),
	name: z.string().describe("In the game's language."),
	gold: YIELD_PURCHASES.extend({
		tiles: z.array(TILE_PURCHASE).describe("The tiles the city can buy, in plot index order."),
	}).describe("What the gold purchase tab lists. Only gold buys tiles."),
	faith: YIELD_PURCHASES.describe("What the faith purchase tab lists."),
});
