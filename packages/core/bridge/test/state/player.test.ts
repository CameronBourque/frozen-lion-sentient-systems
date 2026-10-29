// Tests for player.ts: the schema for the top bar's numbers.

import { describe, expect, test } from "vitest";
import { PLAYER } from "../../src/state/player.js";

const SECTION = {
	gold: { balance: 9610, perTurn: 265.1 },
	faith: { balance: 2357, perTurn: 109 },
	science: 123.5,
	culture: 216.6,
	tourism: 92,
	income: {
		gold: { total: 475.1, cities: 420 },
		faith: { total: 109 },
		science: { total: 123.5 },
		culture: { total: 216.6 },
		expenses: { total: 210, cities: 117, units: 88, deals: 5 },
		cities: [],
		unitUpkeep: [],
		deals: [],
	},
	tradeRoutes: { active: 17, capacity: 20 },
	favor: { balance: 335, perTurn: 3 },
};

describe("PLAYER", () => {
	test("accepts the top bar's numbers", () => {
		expect(PLAYER.parse(SECTION)).toEqual(SECTION);
	});

	test("accepts no trade routes and no favor", () => {
		const rest = { gold: SECTION.gold, faith: SECTION.faith, science: 1, culture: 2, tourism: 0, income: SECTION.income };

		expect(PLAYER.parse(rest)).toEqual(rest);
	});

	test("rejects a section without gold", () => {
		expect(PLAYER.safeParse({ ...SECTION, gold: undefined }).success).toBe(false);
	});
});
