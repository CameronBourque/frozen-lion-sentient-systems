// Tests for captured-cities.ts: the schema for what the player can do with a captured or rebelled
// city.

import { describe, expect, test } from "vitest";
import { CAPTURED_CITIES_CHOICE } from "../../src/choices/captured-cities.js";

const CHOICE = [
	{
		kind: "captured" as const,
		city: 131073,
		name: "Caguana",
		x: 47,
		y: 40,
		population: 1,
		districts: 0,
		options: [
			{ type: "LIBERATE_FOUNDER", player: 15, description: "Liberating a city will return it to one of their previous owners." },
			{ type: "KEEP", description: "Keeping this opponent's final city will give all major powers 100 [ICON_STAT_GRIEVANCE] Grievances against us." },
			{ type: "RAZE", blocked: ["You cannot raze a major civilization's original capital."] },
		],
	},
	{
		kind: "disloyal" as const,
		city: 196610,
		name: "Kish",
		x: 5,
		y: 6,
		population: 4,
		districts: 1,
		options: [{ type: "KEEP", description: "Keep this city." }, { type: "REJECT", description: "Refuse to let this city join your empire." }],
	},
];

describe("CAPTURED_CITIES_CHOICE", () => {
	test("accepts a captured and a rebelled city", () => {
		expect(CAPTURED_CITIES_CHOICE.parse(CHOICE)).toEqual(CHOICE);
	});

	test("accepts no captured city choice", () => {
		expect(CAPTURED_CITIES_CHOICE.safeParse(undefined).success).toBe(true);
	});

	test("rejects a city of another kind", () => {
		expect(CAPTURED_CITIES_CHOICE.safeParse([{ ...CHOICE[1], kind: "gifted" }]).success).toBe(false);
	});
});
