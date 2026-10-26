// Tests for religion.ts: the schemas for the pantheon beliefs, and for the religions and beliefs the
// player can found a religion with.

import { describe, expect, test } from "vitest";
import { PANTHEON, RELIGION_CHOICE } from "../../src/choices/religion.js";

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

const FOUNDING = {
	religions: [{ type: "RELIGION_BUDDHISM" }, { type: "RELIGION_CUSTOM", customName: true as const }],
	picks: 2,
	beliefs: [{ type: "BELIEF_FEED_THE_WORLD", class: "BELIEF_CLASS_FOLLOWER", description: "Shrines and Temples provide +3 [ICON_Food] Food." }],
};

describe("RELIGION_CHOICE", () => {
	test("accepts the religions and beliefs before founding", () => {
		expect(RELIGION_CHOICE.parse(FOUNDING)).toEqual(FOUNDING);
	});

	test("accepts beliefs alone once the religion is founded, and no religion choice", () => {
		expect(RELIGION_CHOICE.safeParse({ picks: 1, beliefs: FOUNDING.beliefs }).success).toBe(true);
		expect(RELIGION_CHOICE.safeParse(undefined).success).toBe(true);
	});

	test("rejects a belief without its class", () => {
		expect(RELIGION_CHOICE.safeParse({ ...FOUNDING, beliefs: [{ type: "BELIEF_TITHE", description: "" }] }).success).toBe(false);
	});
});
