// Tests for religion.ts: the schema for the player's pantheon, progress toward a religion, and
// founded religion.

import { describe, expect, test } from "vitest";
import { RELIGION } from "../../src/state/religion.js";

const FOUNDED = {
	pantheon: "BELIEF_GOD_OF_THE_SEA",
	founded: {
		type: "RELIGION_BUDDHISM",
		name: "Buddhism",
		beliefs: ["BELIEF_TITHE"],
		holyCity: 65536,
		majority: 1,
		cities: [{ owner: 0, city: 65536, followers: 5 }],
	},
};

describe("RELIGION", () => {
	test("accepts a founded religion", () => {
		expect(RELIGION.parse(FOUNDED)).toEqual(FOUNDED);
	});

	test("accepts the faith for a pantheon, and a pantheon with a prophet", () => {
		expect(RELIGION.safeParse({ pantheonFaith: 12 }).success).toBe(true);
		expect(RELIGION.safeParse({ pantheon: "BELIEF_GOD_OF_THE_SEA", prophet: true }).success).toBe(true);
	});

	test("rejects a city without its followers", () => {
		expect(RELIGION.safeParse({ ...FOUNDED, founded: { ...FOUNDED.founded, cities: [{ owner: 0, city: 65536 }] } }).success).toBe(false);
	});
});
