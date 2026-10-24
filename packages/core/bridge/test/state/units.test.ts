// Tests for units.ts: the schema for the player's own units, and the health shared with rivals.

import { describe, expect, test } from "vitest";
import { HEALTH, UNIT } from "../../src/state/units.js";

const SCOUT = {
	id: 196608,
	type: "UNIT_SCOUT",
	x: 24,
	y: 15,
	moves: { left: 3, max: 3 },
	health: { value: 100, max: 100 },
	experience: { points: 15, nextLevel: 15 },
	promotions: [],
	availablePromotions: ["PROMOTION_RANGER", "PROMOTION_ALPINE"],
};

describe("UNIT", () => {
	test("accepts a unit with every field", () => {
		expect(UNIT.parse(SCOUT)).toEqual(SCOUT);
	});

	test("accepts a unit without experience or promotions, which the core mod leaves out", () => {
		const unit = { ...SCOUT, experience: undefined, promotions: undefined, availablePromotions: undefined };

		expect(UNIT.safeParse(unit).success).toBe(true);
	});

	test("rejects a unit without moves", () => {
		expect(UNIT.safeParse({ ...SCOUT, moves: undefined }).success).toBe(false);
	});

	test("rejects a promotion that isn't a type name", () => {
		expect(UNIT.safeParse({ ...SCOUT, promotions: [7] }).success).toBe(false);
	});
});

describe("HEALTH", () => {
	test("accepts a value and a most", () => {
		expect(HEALTH.safeParse({ value: 65, max: 100 }).success).toBe(true);
	});

	test("rejects health without its most", () => {
		expect(HEALTH.safeParse({ value: 65 }).success).toBe(false);
	});
});
