// Tests for scoreboard.ts: the schema for the scores of the players.

import { describe, expect, test } from "vitest";
import { SCOREBOARD } from "../../src/state/scoreboard.js";

const ME = {
	player: 0,
	score: 48,
	categories: [{ type: "CATEGORY_CIVICS", name: "Civics", score: 3 }],
	military: 30,
	science: 4,
	culture: 4,
	gold: 107,
	faith: 591,
	favor: 0,
};

describe("SCOREBOARD", () => {
	test("accepts a player with the leader panel's numbers", () => {
		expect(SCOREBOARD.parse([ME])).toEqual([ME]);
	});

	test("accepts a player who has not been met, with no leader panel numbers", () => {
		const unmet = { score: 12, categories: ME.categories };

		expect(SCOREBOARD.parse([ME, unmet])).toEqual([ME, unmet]);
	});

	test("accepts a game without favor", () => {
		const withoutFavor = { ...ME, favor: undefined };

		expect(SCOREBOARD.parse([withoutFavor])).toEqual([withoutFavor]);
	});

	test("rejects a player without a score", () => {
		expect(SCOREBOARD.safeParse([{ player: 3, categories: [] }]).success).toBe(false);
	});
});
