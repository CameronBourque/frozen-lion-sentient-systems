// Tests for emergencies.ts: the schema for the emergency the player has to look at.

import { describe, expect, test } from "vitest";
import { EMERGENCIES_CHOICE } from "../../src/choices/emergencies.js";

const CHOICE = [{
	type: "EMERGENCY_CAPTURE_CITY_STATE",
	name: "Capture City-State",
	description: "A city-state was captured.",
	goal: "Liberate the city.",
	target: 9,
	targetCity: "Hunza",
	hostile: true,
	turnsLeft: 30,
	options: ["join" as const, "reject" as const],
	members: [0, 4],
	goals: ["Liberate Hunza"],
	scoring: ["+1 for each unit in the city"],
	buffs: ["+1 Movement"],
	rewards: { members: ["+1 Envoy"], target: ["Target gold"] },
}];

describe("EMERGENCIES_CHOICE", () => {
	test("accepts an emergency that hasn't begun", () => {
		expect(EMERGENCIES_CHOICE.parse(CHOICE)).toEqual(CHOICE);
	});

	test("accepts an emergency with no city or scoring, and no emergency choice", () => {
		const entry = { ...CHOICE[0]!, targetCity: undefined, scoring: undefined, options: ["acknowledge" as const] };

		expect(EMERGENCIES_CHOICE.safeParse([entry]).success).toBe(true);
		expect(EMERGENCIES_CHOICE.safeParse(undefined).success).toBe(true);
	});

	test("rejects an option the popup doesn't have", () => {
		expect(EMERGENCIES_CHOICE.safeParse([{ ...CHOICE[0], options: ["ignore"] }]).success).toBe(false);
	});
});
