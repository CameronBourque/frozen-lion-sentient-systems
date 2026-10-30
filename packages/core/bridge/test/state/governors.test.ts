// Tests for governors.ts: the schema for the player's governor titles and appointed governors.

import { describe, expect, test } from "vitest";
import { GOVERNORS } from "../../src/state/governors.js";

const SECTION = {
	titles: 1,
	spent: 8,
	appointed: [
		{
			type: "GOVERNOR_THE_MERCHANT",
			name: "Reyna",
			title: "The Financier",
			city: { owner: 0, id: 393221 },
			established: true,
			loyalty: 8,
			turnsToEstablish: 5,
			promotions: ["GOVERNOR_PROMOTION_MERCHANT_LAND_ACQUISITION"],
		},
		{ type: "GOVERNOR_THE_DEFENDER", name: "Victor", title: "The Castellan", neutralized: 4, loyalty: 8, turnsToEstablish: 3, promotions: [] },
	],
};

describe("GOVERNORS", () => {
	test("accepts the titles and appointed governors", () => {
		expect(GOVERNORS.parse(SECTION)).toEqual(SECTION);
	});

	test("accepts a Secret Society, which has no loyalty or turns to establish", () => {
		const owls = { type: "GOVERNOR_OWLS_OF_MINERVA", name: "Owls of Minerva", title: "Secret Society", secret: true as const, promotions: ["GOVERNOR_PROMOTION_OWLS_OF_MINERVA_1"] };

		expect(GOVERNORS.parse({ titles: 0, spent: 1, appointed: [owls] })).toEqual({ titles: 0, spent: 1, appointed: [owls] });
	});

	test("accepts no section without Rise and Fall", () => {
		expect(GOVERNORS.safeParse(undefined).success).toBe(true);
	});

	test("rejects a governor without their promotions", () => {
		expect(GOVERNORS.safeParse({ ...SECTION, appointed: [{ ...SECTION.appointed[1], promotions: undefined }] }).success).toBe(false);
	});
});
