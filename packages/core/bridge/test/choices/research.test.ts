// Tests for research.ts: the schema for the techs and civics the player can research.

import { describe, expect, test } from "vitest";
import { RESEARCH_OPTION } from "../../src/choices/research.js";

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

describe("RESEARCH_OPTION", () => {
	test("accepts a tech with every field", () => {
		expect(RESEARCH_OPTION.parse(SAILING)).toEqual(SAILING);
	});

	test("accepts a tech with no boost, unlocks, or progress", () => {
		expect(RESEARCH_OPTION.safeParse({ type: "TECH_MINING", cost: 12, turns: 1 }).success).toBe(true);
	});

	test("rejects a tech without turns", () => {
		expect(RESEARCH_OPTION.safeParse({ ...SAILING, turns: undefined }).success).toBe(false);
	});

	test("rejects a boost without its trigger", () => {
		expect(RESEARCH_OPTION.safeParse({ ...SAILING, boost: { percent: 40, triggered: false } }).success).toBe(false);
	});

	test("rejects a recommended that isn't true", () => {
		expect(RESEARCH_OPTION.safeParse({ ...SAILING, recommended: false }).success).toBe(false);
	});

	test("accepts a civic, whose unlocks are policies", () => {
		const craftsmanship = { type: "CIVIC_CRAFTSMANSHIP", cost: 20, turns: 1, unlocks: ["POLICY_ILKUM", "POLICY_AGOGE"], recommended: true };

		expect(RESEARCH_OPTION.parse(craftsmanship)).toEqual(craftsmanship);
	});
});
