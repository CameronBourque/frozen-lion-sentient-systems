// Tests for era.ts: the schema for the player's era, score, and age.

import { describe, expect, test } from "vitest";
import { ERA } from "../../src/state/era.js";

const SECTION = {
	type: "ERA_RENAISSANCE",
	name: "Renaissance Era",
	score: 200,
	age: "normal" as const,
	scoreBreakdown: [{ source: "Previous era total", points: 36 }, { source: "Historic Moments", points: 6 }],
	effects: { citizenLoyalty: 1, dedications: [{ type: "COMMEMORATION_ECONOMIC", text: "Reform the Coinage Dedication Bonus" }] },
	civilizations: [{ player: 1, age: "golden" as const }, { player: 2, age: "dark" as const }],
	unmet: 0,
	nextAge: "dark" as const,
	thresholds: { normal: 228, golden: 239 },
	turnsUntilNext: { min: 16, max: 26 },
};

describe("ERA", () => {
	test("accepts the era with its thresholds and turns", () => {
		expect(ERA.parse(SECTION)).toEqual(SECTION);
	});

	test("accepts the final era, with no thresholds or turns", () => {
		const final = { ...SECTION, nextAge: undefined, thresholds: undefined, turnsUntilNext: undefined, final: true as const };

		expect(ERA.parse(final)).toEqual(final);
	});

	test("accepts no normal threshold in the Dramatic Ages mode", () => {
		const section = { ...SECTION, thresholds: { golden: 239 } };

		expect(ERA.parse(section)).toEqual(section);
	});

	test("accepts no section without Rise and Fall", () => {
		expect(ERA.safeParse(undefined).success).toBe(true);
	});

	test("rejects an age the panel doesn't have", () => {
		expect(ERA.safeParse({ ...SECTION, age: "silver" }).success).toBe(false);
	});

	test("rejects a section without its effects", () => {
		expect(ERA.safeParse({ ...SECTION, effects: undefined }).success).toBe(false);
	});
});
