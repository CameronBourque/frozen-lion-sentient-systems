// Tests for rivals.ts: the schemas for rival cities and units.

import { describe, expect, test } from "vitest";
import { RIVAL_CITY, RIVAL_UNIT } from "../../src/state/rivals.js";

const RA_KEDET = {
	owner: 1,
	id: 65536,
	name: "Râ-Kedet",
	x: 30,
	y: 18,
	population: 2,
	capital: true,
	defense: { strength: 13, garrison: { value: 200, max: 200 }, walls: { value: 90, max: 100 } },
};

const WARRIOR = { owner: 1, id: 131073, type: "UNIT_WARRIOR", x: 25, y: 14, health: { value: 100, max: 100 } };

describe("RIVAL_CITY", () => {
	test("accepts a city with walls", () => {
		expect(RIVAL_CITY.parse(RA_KEDET)).toEqual(RA_KEDET);
	});

	test("accepts a city without walls, which the core mod leaves out", () => {
		expect(RIVAL_CITY.safeParse({ ...RA_KEDET, defense: { strength: 13, garrison: { value: 200, max: 200 } } }).success).toBe(true);
	});

	test("rejects a city without its owner", () => {
		expect(RIVAL_CITY.safeParse({ ...RA_KEDET, owner: undefined }).success).toBe(false);
	});
});

describe("RIVAL_UNIT", () => {
	test("accepts a unit with its owner, type, position, and health", () => {
		expect(RIVAL_UNIT.parse(WARRIOR)).toEqual(WARRIOR);
	});

	test("rejects a unit without its health", () => {
		expect(RIVAL_UNIT.safeParse({ ...WARRIOR, health: undefined }).success).toBe(false);
	});
});
