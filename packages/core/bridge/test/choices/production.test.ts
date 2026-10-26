// Tests for production.ts: the schema for what each city can produce.

import { describe, expect, test } from "vitest";
import { PRODUCTION_CITY } from "../../src/choices/production.js";

const ROME = {
	city: 65536,
	name: "Rome",
	units: [
		{ type: "UNIT_SETTLER", cost: 40, turns: 6, blocked: ["This city needs at least 2 [ICON_Citizen] Population."] },
		{ type: "UNIT_SCOUT", cost: 15, turns: 2, progress: 5 },
		{ type: "UNIT_WARRIOR", cost: 20, turns: 3, corps: { cost: 30, turns: 5 }, army: { cost: 40, turns: 7, blocked: [] } },
	],
};

describe("PRODUCTION_CITY", () => {
	test("accepts a city with units that are blocked, in progress, and with formations", () => {
		expect(PRODUCTION_CITY.parse(ROME)).toEqual(ROME);
	});

	test("accepts a city with nothing to produce", () => {
		expect(PRODUCTION_CITY.safeParse({ ...ROME, units: [] }).success).toBe(true);
	});

	test("rejects a city without its name", () => {
		expect(PRODUCTION_CITY.safeParse({ ...ROME, name: undefined }).success).toBe(false);
	});

	test("rejects a unit without turns", () => {
		expect(PRODUCTION_CITY.safeParse({ ...ROME, units: [{ type: "UNIT_SCOUT", cost: 15 }] }).success).toBe(false);
	});

	test("rejects a reason that isn't text", () => {
		expect(PRODUCTION_CITY.safeParse({ ...ROME, units: [{ ...ROME.units[0], blocked: [7] }] }).success).toBe(false);
	});
});
