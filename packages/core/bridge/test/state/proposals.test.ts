// Tests for proposals.ts: the schema for the deals put to the player.

import { describe, expect, test } from "vitest";
import { PROPOSALS } from "../../src/state/proposals.js";

const KUPE = {
	from: 4,
	gift: false,
	valid: true,
	asks: [
		{ id: 2, kind: "resource" as const, resource: "RESOURCE_HORSES", amount: 10 },
		{ id: 6, kind: "city" as const, city: { owner: 0, id: 131073 }, name: "Bagacum" },
		{ id: 7, kind: "resource" as const, resource: "RESOURCE_NITER", amount: 2, locked: true as const, with: 6 },
	],
	offers: [
		{ id: 3, kind: "agreement" as const, agreement: "DIPLOACTION_OPEN_BORDERS", turns: 20 },
		{ id: 5, kind: "gold" as const, amount: 3, turns: 30 },
	],
};

describe("PROPOSALS", () => {
	test("accepts a proposal with a city and its items", () => {
		expect(PROPOSALS.parse([KUPE])).toEqual([KUPE]);
	});

	test("accepts no proposals", () => {
		expect(PROPOSALS.parse([])).toEqual([]);
	});

	test("accepts an alliance, a joint war, and an item that is unacceptable", () => {
		const offers = [
			{ id: 1, kind: "agreement" as const, agreement: "DIPLOACTION_ALLIANCE", allianceType: "ALLIANCE_RESEARCH", turns: 0 },
			{ id: 2, kind: "agreement" as const, agreement: "DIPLOACTION_JOINT_WAR", target: 5, war: "WAR_FORMAL" },
			{ id: 3, kind: "favor" as const, amount: 5, unacceptable: true as const },
		];

		expect(PROPOSALS.parse([{ ...KUPE, offers }])).toEqual([{ ...KUPE, offers }]);
	});

	test("rejects an item of a kind the screen doesn't have", () => {
		expect(PROPOSALS.safeParse([{ ...KUPE, asks: [{ id: 1, kind: "land" }] }]).success).toBe(false);
	});

	test("rejects a proposal without its items", () => {
		expect(PROPOSALS.safeParse([{ ...KUPE, offers: undefined }]).success).toBe(false);
	});
});
