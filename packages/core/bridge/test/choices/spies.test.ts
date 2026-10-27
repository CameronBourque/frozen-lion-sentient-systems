// Tests for spies.ts: the schema for the escape routes of the player's escaping spy.

import { describe, expect, test } from "vitest";
import { SPIES_CHOICE } from "../../src/choices/spies.js";

const CHOICE = [{
	spy: 2555922,
	name: "Laurenza",
	city: { owner: 4, id: 65536, name: "Istanbul" },
	loot: "None",
	pursuer: "Police",
	description: "Choose the escape route out of the city for your agent.",
	routes: [
		{ type: "DISTRICT_AERODROME", name: "Airplane", turns: 1, blocked: ["No Aerodrome in city"] },
		{ type: "DISTRICT_CITY_CENTER", name: "Foot", turns: 4 },
	],
}];

describe("SPIES_CHOICE", () => {
	test("accepts an escaping spy with its routes", () => {
		expect(SPIES_CHOICE.parse(CHOICE)).toEqual(CHOICE);
	});

	test("accepts no spy choice", () => {
		expect(SPIES_CHOICE.safeParse(undefined).success).toBe(true);
	});

	test("rejects a route without its turns", () => {
		expect(SPIES_CHOICE.safeParse([{ ...CHOICE[0], routes: [{ type: "DISTRICT_CITY_CENTER", name: "Foot" }] }]).success).toBe(false);
	});
});
