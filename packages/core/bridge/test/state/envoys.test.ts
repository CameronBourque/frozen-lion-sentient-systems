// Tests for envoys.ts: the schema for the player's envoy tokens, influence, and met city-states.

import { describe, expect, test } from "vitest";
import { ENVOYS } from "../../src/state/envoys.js";

const SECTION = {
	tokens: 4,
	influence: { points: 0, perTurn: 0, threshold: 50, envoys: 1 },
	cityStates: [
		{ player: 12, name: "Samarkand", type: "TRADE", envoys: 2, suzerain: 1, suzerainNeeds: 4 },
		{ player: 13, name: "Cahokia", type: "TRADE", envoys: 1, suzerainUnmet: true as const, suzerainNeeds: 4 },
		{ player: 15, name: "Caguana", envoys: 1, suzerainNeeds: 3 },
	],
};

describe("ENVOYS", () => {
	test("accepts the tokens, influence, and city-states", () => {
		expect(ENVOYS.parse(SECTION)).toEqual(SECTION);
	});

	test("accepts no city-states met", () => {
		expect(ENVOYS.safeParse({ ...SECTION, cityStates: [] }).success).toBe(true);
	});

	test("rejects a city-state without the envoys to be suzerain", () => {
		expect(ENVOYS.safeParse({ ...SECTION, cityStates: [{ player: 12, name: "Samarkand", envoys: 2 }] }).success).toBe(false);
	});
});
