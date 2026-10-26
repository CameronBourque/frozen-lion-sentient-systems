// Tests for government.ts: the schema for the player's government and its policy slots.

import { describe, expect, test } from "vitest";
import { GOVERNMENT } from "../../src/choices/government.js";

const CHIEFDOM = {
	type: "GOVERNMENT_CHIEFDOM",
	slots: [
		{ slot: 0, type: "SLOT_MILITARY" },
		{ slot: 1, type: "SLOT_ECONOMIC", policy: "POLICY_GOD_KING" },
	],
};

describe("GOVERNMENT", () => {
	test("accepts a government with an empty and a filled slot", () => {
		expect(GOVERNMENT.parse(CHIEFDOM)).toEqual(CHIEFDOM);
	});

	test("accepts no government, with no slots", () => {
		expect(GOVERNMENT.safeParse({ slots: [] }).success).toBe(true);
	});

	test("rejects a slot without its index", () => {
		expect(GOVERNMENT.safeParse({ ...CHIEFDOM, slots: [{ type: "SLOT_MILITARY" }] }).success).toBe(false);
	});
});
