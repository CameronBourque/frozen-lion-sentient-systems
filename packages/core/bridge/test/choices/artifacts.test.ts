// Tests for artifacts.ts: the schema for whose artifact the player's archaeologist uncovers.

import { describe, expect, test } from "vitest";
import { ARTIFACTS_CHOICE } from "../../src/choices/artifacts.js";

const CHOICE = [{
	archaeologist: 2686995,
	name: "Remo",
	x: 48,
	y: 25,
	era: "ERA_INDUSTRIAL",
	description: "Your Archaeologist Remo has discovered an ancient battlefield littered with items from Trajan and Free Cities.",
	options: [{ player: 0, name: "Trajan" }, { player: 62, name: "Free Cities" }],
}];

describe("ARTIFACTS_CHOICE", () => {
	test("accepts an artifact from a battlefield", () => {
		expect(ARTIFACTS_CHOICE.parse(CHOICE)).toEqual(CHOICE);
	});

	test("accepts no artifact choice", () => {
		expect(ARTIFACTS_CHOICE.safeParse(undefined).success).toBe(true);
	});

	test("rejects an option without its player", () => {
		expect(ARTIFACTS_CHOICE.safeParse([{ ...CHOICE[0], options: [{ name: "Trajan" }] }]).success).toBe(false);
	});
});
