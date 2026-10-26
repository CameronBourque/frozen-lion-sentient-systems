// Tests for government.ts: the schemas for the player's government, its policy slots, and the
// policies the player can slot.

import { describe, expect, test } from "vitest";
import { GOVERNMENT, POLICIES } from "../../src/choices/government.js";

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

const POLICY_CHOICE = {
	canChange: false,
	unlock: { cost: 50, yield: "YIELD_GOLD", blocked: ["You Need 50 [ICON_GoldLarge] Gold"] },
	options: {
		SLOT_MILITARY: [{ type: "POLICY_SURVEY", description: "Double experience for recon units." }],
		SLOT_ECONOMIC: [{ type: "POLICY_ILKUM", description: "+30% [ICON_Production] Production toward Builders.", new: true as const }],
	},
};

describe("POLICIES", () => {
	test("accepts every field", () => {
		expect(POLICIES.parse(POLICY_CHOICE)).toEqual(POLICY_CHOICE);
	});

	test("accepts no unlock and no options", () => {
		expect(POLICIES.safeParse({ canChange: true }).success).toBe(true);
	});

	test("rejects an unlock without its yield", () => {
		expect(POLICIES.safeParse({ ...POLICY_CHOICE, unlock: { cost: 50 } }).success).toBe(false);
	});

	test("rejects a new that isn't true", () => {
		expect(POLICIES.safeParse({ canChange: true, options: { SLOT_MILITARY: [{ type: "POLICY_SURVEY", description: "", new: false }] } }).success).toBe(false);
	});
});
