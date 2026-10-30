// Tests for cities.ts: the schema for the player's own cities.

import { describe, expect, test } from "vitest";
import { CITY, DEFENSE } from "../../src/state/cities.js";

const ROME = {
	id: 65536,
	name: "Rome",
	x: 17,
	y: 14,
	population: 3,
	amenities: { have: 2, need: 2, mood: "HAPPINESS_CONTENT", warWeariness: 0 },
	defense: { strength: 13, garrison: { value: 200, max: 200 } },
	districts: [{
		type: "DISTRICT_CITY_CENTER",
		x: 17,
		y: 14,
		complete: true,
		pillaged: false,
		buildings: [{ type: "BUILDING_MONUMENT", pillaged: false }],
	}],
	governor: { type: "GOVERNOR_THE_MERCHANT", established: true },
	growth: { foodSurplus: 3, housing: 6, rate: "normal" as const, turnsUntilGrowth: 2 },
	loyalty: { value: 100, max: 100, perTurn: 21 },
	production: { type: "UNIT_SLINGER", turnsLeft: 2 },
	yields: { food: 9, production: 6, gold: 8, science: 3.5, culture: 3.8, faith: 0 },
};

describe("CITY", () => {
	test("accepts a city with every field", () => {
		expect(CITY.parse(ROME)).toEqual(ROME);
	});

	test("accepts a city without loyalty, production, a mood, or a growth count, which the core mod leaves out", () => {
		const city = {
			...ROME,
			amenities: { have: 2, need: 2, warWeariness: 0 },
			growth: { foodSurplus: 0, housing: 6, rate: "slowed" as const },
			governor: undefined,
			loyalty: undefined,
			production: undefined,
		};

		expect(CITY.safeParse(city).success).toBe(true);
	});

	test("accepts a starving city and a production with no type", () => {
		const city = { ...ROME, growth: { foodSurplus: -2, housing: 6, rate: "halted" as const, turnsUntilLoss: 4 }, production: { turnsLeft: 3 } };

		expect(CITY.safeParse(city).success).toBe(true);
	});

	test("rejects a growth rate the tab doesn't have", () => {
		const city = { ...ROME, growth: { ...ROME.growth, rate: "fast" } };

		expect(CITY.safeParse(city).success).toBe(false);
	});

	test("rejects a city without yields", () => {
		expect(CITY.safeParse({ ...ROME, yields: undefined }).success).toBe(false);
	});

	test("rejects a city without its defense", () => {
		expect(CITY.safeParse({ ...ROME, defense: undefined }).success).toBe(false);
	});

	test("rejects a building without its pillaged flag", () => {
		const city = { ...ROME, districts: [{ ...ROME.districts[0], buildings: [{ type: "BUILDING_MONUMENT" }] }] };

		expect(CITY.safeParse(city).success).toBe(false);
	});
});

describe("DEFENSE", () => {
	test("accepts a defense with walls", () => {
		expect(DEFENSE.safeParse({ strength: 20, garrison: { value: 150, max: 200 }, walls: { value: 90, max: 100 } }).success).toBe(true);
	});

	test("accepts a defense without walls, which the core mod leaves out", () => {
		expect(DEFENSE.safeParse({ strength: 13, garrison: { value: 200, max: 200 } }).success).toBe(true);
	});

	test("rejects a defense without its garrison", () => {
		expect(DEFENSE.safeParse({ strength: 13 }).success).toBe(false);
	});
});
