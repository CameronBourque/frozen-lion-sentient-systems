// Tests for techs.ts: the schema for the techs the player can research.

import { describe, expect, test } from "vitest";
import { TECH_OPTION } from "../../src/choices/techs.js";

const SAILING = {
	type: "TECH_SAILING",
	cost: 25,
	turns: 1,
	progress: 10,
	boost: { percent: 40, trigger: "Found a city on the Coast.", triggered: false },
	unlocks: ["UNIT_GALLEY", "IMPROVEMENT_FISHING_BOATS"],
	description: "Allows units to embark.",
	current: true as const,
	recommended: true as const,
};

describe("TECH_OPTION", () => {
	test("accepts a tech with every field", () => {
		expect(TECH_OPTION.parse(SAILING)).toEqual(SAILING);
	});

	test("accepts a tech with no boost, unlocks, or progress", () => {
		expect(TECH_OPTION.safeParse({ type: "TECH_MINING", cost: 12, turns: 1 }).success).toBe(true);
	});

	test("rejects a tech without turns", () => {
		expect(TECH_OPTION.safeParse({ ...SAILING, turns: undefined }).success).toBe(false);
	});

	test("rejects a boost without its trigger", () => {
		expect(TECH_OPTION.safeParse({ ...SAILING, boost: { percent: 40, triggered: false } }).success).toBe(false);
	});

	test("rejects a recommended that isn't true", () => {
		expect(TECH_OPTION.safeParse({ ...SAILING, recommended: false }).success).toBe(false);
	});
});
