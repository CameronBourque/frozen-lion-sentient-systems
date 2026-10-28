// Tests for dedications.ts: the schema for the dedications the player may make for the era that began.

import { describe, expect, test } from "vitest";
import { DEDICATIONS_CHOICE } from "../../src/choices/dedications.js";

const CHOICE = {
	era: "Classical Era",
	age: "heroic" as const,
	picks: 3,
	options: [
		{ type: "COMMEMORATION_SCIENTIFIC", name: "Free Inquiry", description: "Free Inquiry Golden Age:\n[ICON_TechBoosted] Eurekas provide an additional 10% of technology costs." },
		{ type: "COMMEMORATION_CULTURAL", name: "Pen, Brush, and Voice", description: "Pen, Brush, and Voice Golden Age:\n[ICON_CivicBoosted] Inspirations provide an additional 10% of civic costs." },
	],
};

describe("DEDICATIONS_CHOICE", () => {
	test("accepts the dedications of a heroic age", () => {
		expect(DEDICATIONS_CHOICE.parse(CHOICE)).toEqual(CHOICE);
	});

	test("accepts no dedication choice", () => {
		expect(DEDICATIONS_CHOICE.safeParse(undefined).success).toBe(true);
	});

	test("rejects an age the popup doesn't use", () => {
		expect(DEDICATIONS_CHOICE.safeParse({ ...CHOICE, age: "silver" }).success).toBe(false);
	});

	test("rejects an option without its type", () => {
		expect(DEDICATIONS_CHOICE.safeParse({ ...CHOICE, options: [{ name: "Free Inquiry", description: "Text" }] }).success).toBe(false);
	});
});
