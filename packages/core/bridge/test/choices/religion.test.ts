// Tests for religion.ts: the schema for the pantheon beliefs the player can found a pantheon with.

import { describe, expect, test } from "vitest";
import { PANTHEON } from "../../src/choices/religion.js";

const CHOICE = {
	beliefs: [{ type: "BELIEF_SACRED_PATH", description: "Holy Site districts get +1 [ICON_Faith] Faith from adjacent Rainforest tiles." }],
};

describe("PANTHEON", () => {
	test("accepts the beliefs", () => {
		expect(PANTHEON.parse(CHOICE)).toEqual(CHOICE);
	});

	test("accepts no pantheon choice", () => {
		expect(PANTHEON.safeParse(undefined).success).toBe(true);
	});

	test("rejects a belief without its description", () => {
		expect(PANTHEON.safeParse({ beliefs: [{ type: "BELIEF_SACRED_PATH" }] }).success).toBe(false);
	});
});
