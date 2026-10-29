// Tests for world-congress.ts: the schema for what the player decides in a World Congress session.

import { describe, expect, test } from "vitest";
import { WORLD_CONGRESS_CHOICE } from "../../src/choices/world-congress.js";

const REGULAR = {
	session: "regular" as const,
	favor: 196,
	voteCosts: [0, 4, 12],
	resolutions: [{
		type: "RESOLUTION_LUXURY_POLICY",
		name: "Luxury Policy",
		options: { A: "Improve luxury", B: "Ban luxury" },
		targetType: "ResourceType",
		targets: [{ index: 1, name: "Marble" }, { index: 2, name: "Silk" }],
		favored: [2],
		disfavored: [],
	}],
	proposals: [{ type: "WC_EMERGENCY_BACKSTAB", name: "Betrayal Emergency", description: "Punish them.", sender: 0, target: 10 }],
};

describe("WORLD_CONGRESS_CHOICE", () => {
	test("accepts a regular session", () => {
		expect(WORLD_CONGRESS_CHOICE.parse(REGULAR)).toEqual(REGULAR);
	});

	test("accepts the results and effects at the results blocker", () => {
		const review = {
			session: "review" as const,
			favor: 122,
			results: [{ name: "Luxury Policy", elected: "B", text: "Ban luxury", target: "Marble", votes: { A: 3, B: 52 }, voters: [{ player: 0, name: "Trajan", option: "B" as const, target: "Marble", votes: 3 }] }],
			effects: [{ name: "Luxury Policy", elected: "B", text: "Ban luxury", target: "Marble", turnsLeft: 18 }],
		};

		expect(WORLD_CONGRESS_CHOICE.parse(review)).toEqual(review);
	});

	test("accepts the proposals to call a Special Session for, and no choice", () => {
		const available = { favor: 142, available: [{ type: "WC_EMERGENCY_REQUEST_AID", name: "Aid Request", description: "Help.", target: 0, cost: 30, disabled: false }] };

		expect(WORLD_CONGRESS_CHOICE.parse(available)).toEqual(available);
		expect(WORLD_CONGRESS_CHOICE.safeParse(undefined).success).toBe(true);
	});

	test("rejects a session the congress screen doesn't have", () => {
		expect(WORLD_CONGRESS_CHOICE.safeParse({ ...REGULAR, session: "emergency" }).success).toBe(false);
	});
});
