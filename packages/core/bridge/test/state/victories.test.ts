// Tests for victories.ts: the schema for the progress toward each victory.

import { describe, expect, test } from "vitest";
import { VICTORIES } from "../../src/state/victories.js";

const STAGES = [
	{
		progress: 0.5,
		done: false,
		tasks: [
			{ kind: "district" as const, type: "DISTRICT_SPACEPORT", done: true },
			{ kind: "tech" as const, type: "TECH_ROCKETRY", done: true },
			{ kind: "project" as const, type: "PROJECT_LAUNCH_EARTH_SATELLITE", done: false },
		],
	},
];

const SCIENCE = [
	{ player: 1, progress: 0.5, techs: 20, sciencePerTurn: 8, stages: STAGES },
	{ unmet: true as const },
];

const TOURISTS = { domesticTourists: 3, visitingTourists: 2, requiredTourists: 8 };

describe("VICTORIES", () => {
	test("accepts a player and one that has not been met", () => {
		expect(VICTORIES.parse({ science: SCIENCE })).toEqual({ science: SCIENCE });
	});

	test("accepts the light years of the expedition", () => {
		const science = [{ ...SCIENCE[0], lightYears: { current: 5, needed: 50, perTurn: 2.3 } }];

		expect(VICTORIES.parse({ science })).toEqual({ science });
	});

	test("rejects a science task of a kind the tab doesn't have", () => {
		const stages = [{ ...STAGES[0], tasks: [{ kind: "wonder", type: "WONDER_X", done: true }] }];

		expect(VICTORIES.safeParse({ science: [{ ...SCIENCE[0], stages }] }).success).toBe(false);
	});

	test("accepts the tourists of a player and of one that has not been met", () => {
		const culture = [
			{
				player: 1,
				progress: 0,
				tourismPerTurn: 1,
				culturePerTurn: 2.5,
				...TOURISTS,
				touristsFromYou: 5,
				tourismBreakdown: ["Tourism: 73 (current)"],
				turnsToVictory: 12,
				dominance: "you" as const,
			},
			{ player: 0, progress: 0, tourismPerTurn: 1, culturePerTurn: 2.5, ...TOURISTS, dominating: 1, dominatedBy: 2 },
			{ unmet: true as const, ...TOURISTS, touristsFromYou: 0 },
		];

		expect(VICTORIES.parse({ culture })).toEqual({ culture });
	});

	test("rejects a player of the culture victory without the tourists", () => {
		const entry = { player: 0, progress: 0, tourismPerTurn: 1, culturePerTurn: 2.5 };

		expect(VICTORIES.safeParse({ culture: [entry] }).success).toBe(false);
		expect(VICTORIES.safeParse({ culture: [{ unmet: true }] }).success).toBe(false);
	});

	test("rejects a dominance that is not you or them", () => {
		const entry = { player: 1, progress: 0, tourismPerTurn: 1, culturePerTurn: 2.5, ...TOURISTS, dominance: "us" };

		expect(VICTORIES.safeParse({ culture: [entry] }).success).toBe(false);
	});

	test("accepts the capitals of a player and of one that has not been met", () => {
		const domination = [
			{ player: 0, progress: 0.08, military: 20, hasOriginalCapital: true, capitalsCaptured: 2, capturedCapitals: [1] },
			{ unmet: true as const, hasOriginalCapital: false, capitalsCaptured: 0 },
			{ player: 2, progress: 0, military: 3 },
		];

		expect(VICTORIES.parse({ domination })).toEqual({ domination });
	});

	test("accepts the religion of a player and of one that has not been met", () => {
		const religion = [
			{
				player: 0,
				progress: 0,
				cities: 3,
				faithPerTurn: 1.3,
				religion: "RELIGION_BUDDHISM",
				religionName: "Buddhism",
				civsConverted: 3,
				convertedCivs: [0, 1],
			},
			{ unmet: true as const, religion: "RELIGION_ISLAM", religionName: "Islam", civsConverted: 1 },
		];

		expect(VICTORIES.parse({ religion })).toEqual({ religion });
	});

	test("accepts the diplomatic points of a player and of one that has not been met", () => {
		const diplomatic = [
			{ player: 0, progress: 0.2, points: 4, required: 20, breakdown: ["2 from Congress Participation"] },
			{ unmet: true as const, points: 2, required: 20 },
		];

		expect(VICTORIES.parse({ diplomatic })).toEqual({ diplomatic });
	});

	test("rejects an unmet player of the diplomatic victory without points", () => {
		expect(VICTORIES.safeParse({ diplomatic: [{ unmet: true }] }).success).toBe(false);
	});

	test("accepts no victories that are on", () => {
		expect(VICTORIES.parse({})).toEqual({});
	});

	test("rejects a player without the tooltip's numbers", () => {
		expect(VICTORIES.safeParse({ science: [{ player: 1, progress: 0.5, stages: STAGES }] }).success).toBe(false);
	});
});
