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
	buildings: [
		{ type: "BUILDING_GRANARY", district: "DISTRICT_CITY_CENTER", cost: 32, turns: 5, progress: 8 },
		{ type: "BUILDING_SHRINE", district: "DISTRICT_HOLY_SITE", cost: 50, turns: 8, repair: true as const, blocked: ["Needs a river."] },
	],
	districts: [{
		type: "DISTRICT_CAMPUS",
		cost: 29,
		turns: 6,
		tiles: [{ x: 17, y: 13, adjacency: { science: 1 } }, { x: 16, y: 14 }],
		purchaseTiles: [{ x: 19, y: 14, adjacency: { science: 3 } }],
	}],
	wonders: [{ type: "BUILDING_PYRAMIDS", cost: 110, turns: 18, tiles: [], purchaseTiles: [{ x: 17, y: 17 }] }],
};

describe("PRODUCTION_CITY", () => {
	test("accepts a city with units that are blocked, in progress, and with formations", () => {
		expect(PRODUCTION_CITY.parse(ROME)).toEqual(ROME);
	});

	test("accepts a city with nothing to produce", () => {
		expect(PRODUCTION_CITY.safeParse({ ...ROME, units: [], buildings: [], districts: [], wonders: [] }).success).toBe(true);
	});

	test("rejects a city without its buildings", () => {
		expect(PRODUCTION_CITY.safeParse({ ...ROME, buildings: undefined }).success).toBe(false);
	});

	test("rejects a district without its tiles to buy", () => {
		expect(PRODUCTION_CITY.safeParse({ ...ROME, districts: [{ ...ROME.districts[0], purchaseTiles: undefined }] }).success).toBe(false);
	});

	test("rejects an adjacency bonus that isn't a number", () => {
		const tile = { x: 17, y: 13, adjacency: { science: "1" } };

		expect(PRODUCTION_CITY.safeParse({ ...ROME, districts: [{ ...ROME.districts[0], tiles: [tile] }] }).success).toBe(false);
	});

	test("rejects a wonder without its tiles", () => {
		expect(PRODUCTION_CITY.safeParse({ ...ROME, wonders: [{ ...ROME.wonders[0], tiles: undefined }] }).success).toBe(false);
	});

	test("rejects a repair that isn't true", () => {
		expect(PRODUCTION_CITY.safeParse({ ...ROME, buildings: [{ ...ROME.buildings[0], repair: false }] }).success).toBe(false);
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
