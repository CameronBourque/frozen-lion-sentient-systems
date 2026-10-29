// Tests for resources.ts: the schema for the player's resources.

import { describe, expect, test } from "vitest";
import { RESOURCES } from "../../src/state/resources.js";

const SECTION = [
	{
		type: "RESOURCE_IRON",
		name: "Iron",
		class: "strategic" as const,
		perTurn: 1,
		stockpile: 40,
		max: 105,
		sources: [
			{ kind: "city" as const, city: { owner: 0, id: 65536 }, name: "Rome", amount: 2 },
			{ kind: "deal" as const, player: 4, turnsLeft: 5, amount: 2 },
			{ kind: "units" as const, amount: -2 },
			{ kind: "other" as const, amount: 2 },
		],
	},
	{
		type: "RESOURCE_TURTLES",
		name: "Turtles",
		class: "luxury" as const,
		total: 3,
		cities: [{ city: { owner: 0, id: 65536 }, amount: 1 }],
		sources: [{ kind: "suzerain" as const, player: 5, amount: 1 }],
	},
];

describe("RESOURCES", () => {
	test("accepts a strategic resource's stockpile and a luxury's cities", () => {
		expect(RESOURCES.parse(SECTION)).toEqual(SECTION);
	});

	test("accepts no resources", () => {
		expect(RESOURCES.parse([])).toEqual([]);
	});

	test("rejects a source of a kind the report doesn't have", () => {
		const resource = { ...SECTION[1], sources: [{ kind: "market", amount: 1 }] };

		expect(RESOURCES.safeParse([resource]).success).toBe(false);
	});

	test("rejects a resource without its sources", () => {
		expect(RESOURCES.safeParse([{ ...SECTION[1], sources: undefined }]).success).toBe(false);
	});
});
