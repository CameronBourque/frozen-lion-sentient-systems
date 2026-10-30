// Tests for envoys.ts: the schema for the player's envoy tokens, influence, city-state bonuses, and
// met city-states.

import { describe, expect, test } from "vitest";
import { ENVOYS } from "../../src/state/envoys.js";

const SECTION = {
	tokens: 4,
	influence: { points: 0, perTurn: 0, threshold: 50, envoys: 1 },
	bonuses: { TRADE: ["+2 [ICON_Gold] Gold in the [ICON_Capital] Capital", "+4 [ICON_Gold] Gold", "+6 [ICON_Gold] Gold"] },
	cityStates: [
		{
			player: 12,
			name: "Samarkand",
			type: "TRADE",
			envoys: 2,
			suzerain: 1,
			suzerainNeeds: 4,
			suzerainBonus: "Your Builders can now make Trading Dome improvements.",
			suzerainBonusDisabled: true as const,
			resources: [{ type: "RESOURCE_SILK", amount: 1 }],
			quests: [{ type: "QUEST_TRAIN_UNIT_TYPE", name: "Train a Spearman.", description: "Train a Spearman military unit.", reward: "[ICON_Envoy] 1 Envoy" }],
			influencedBy: [{ player: 1, envoys: 3 }, { player: 0, envoys: 2 }],
		},
		{ player: 13, name: "Cahokia", type: "TRADE", envoys: 1, suzerainUnmet: true as const, suzerainNeeds: 4, influencedBy: [{ unmet: true as const, envoys: 3 }, { player: 0, envoys: 1 }] },
		{ player: 15, name: "Caguana", envoys: 0, suzerainNeeds: 3, influencedBy: [] },
	],
};

describe("ENVOYS", () => {
	test("accepts the tokens, influence, bonuses, and city-states", () => {
		expect(ENVOYS.parse(SECTION)).toEqual(SECTION);
	});

	test("accepts no city-states met, without bonuses", () => {
		expect(ENVOYS.safeParse({ tokens: 0, influence: SECTION.influence, cityStates: [] }).success).toBe(true);
	});

	test("rejects a city-state without the envoys to be suzerain", () => {
		expect(ENVOYS.safeParse({ ...SECTION, cityStates: [{ player: 12, name: "Samarkand", envoys: 2, influencedBy: [] }] }).success).toBe(false);
	});

	test("rejects a quest without its reward", () => {
		const quest = { type: "QUEST_TRAIN_UNIT_TYPE", name: "Train a Spearman.", description: "" };

		expect(ENVOYS.safeParse({ ...SECTION, cityStates: [{ ...SECTION.cityStates[2], quests: [quest] }] }).success).toBe(false);
	});
});
