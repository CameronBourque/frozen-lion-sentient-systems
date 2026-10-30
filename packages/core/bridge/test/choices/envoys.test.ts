// Tests for envoys.ts: the schema for the city-states the player can send envoys to.

import { describe, expect, test } from "vitest";
import { ENVOY_CHOICE } from "../../src/choices/envoys.js";

describe("ENVOY_CHOICE", () => {
	test("accepts the tokens and city-states", () => {
		expect(ENVOY_CHOICE.parse({ tokens: 4, cityStates: [12, 13, 14] })).toEqual({ tokens: 4, cityStates: [12, 13, 14] });
	});

	test("accepts no envoy choice", () => {
		expect(ENVOY_CHOICE.safeParse(undefined).success).toBe(true);
	});

	test("rejects a city-state by name", () => {
		expect(ENVOY_CHOICE.safeParse({ tokens: 1, cityStates: ["Samarkand"] }).success).toBe(false);
	});
});
