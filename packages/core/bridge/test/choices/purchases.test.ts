// Tests for purchases.ts: the schema for what each city can buy.

import { describe, expect, test } from "vitest";
import { PURCHASE_CITY } from "../../src/choices/purchases.js";

const ROME = {
	city: 65536,
	name: "Rome",
	gold: {
		units: [
			{ type: "UNIT_BUILDER", cost: 100 },
			{ type: "UNIT_SETTLER", cost: 160, blocked: ["Not enough [ICON_Gold] Gold in treasury to purchase this."] },
			{ type: "UNIT_WARRIOR", cost: 80, corps: { cost: 160 }, army: { cost: 240, blocked: [] } },
		],
		buildings: [{ type: "BUILDING_GRANARY", cost: 130 }],
		districts: [{ type: "DISTRICT_CAMPUS", cost: 195 }],
	},
};

describe("PURCHASE_CITY", () => {
	test("accepts a city with units, buildings, and districts to buy with gold", () => {
		expect(PURCHASE_CITY.parse(ROME)).toEqual(ROME);
	});

	test("accepts a city that can buy nothing", () => {
		expect(PURCHASE_CITY.safeParse({ ...ROME, gold: { units: [], buildings: [], districts: [] } }).success).toBe(true);
	});

	test("rejects a city without its gold purchases", () => {
		expect(PURCHASE_CITY.safeParse({ ...ROME, gold: undefined }).success).toBe(false);
	});

	test("rejects a unit without its cost", () => {
		expect(PURCHASE_CITY.safeParse({ ...ROME, gold: { ...ROME.gold, units: [{ type: "UNIT_BUILDER" }] } }).success).toBe(false);
	});

	test("rejects a corps without its cost", () => {
		const warrior = { ...ROME.gold.units[2], corps: { blocked: [] } };

		expect(PURCHASE_CITY.safeParse({ ...ROME, gold: { ...ROME.gold, units: [warrior] } }).success).toBe(false);
	});
});
