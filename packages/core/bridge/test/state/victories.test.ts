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

	test("accepts every victory", () => {
		const victories = {
			science: SCIENCE,
			culture: [{ player: 0, progress: 0, tourismPerTurn: 1, culturePerTurn: 2.5 }],
			domination: [{ player: 0, progress: 0.08, military: 20 }],
			religion: [{ player: 0, progress: 0, cities: 3, faithPerTurn: 1.3 }],
			diplomatic: [{ player: 0, progress: 0.2, points: 4, required: 20 }],
		};

		expect(VICTORIES.parse(victories)).toEqual(victories);
	});

	test("accepts no victories that are on", () => {
		expect(VICTORIES.parse({})).toEqual({});
	});

	test("rejects a player without the tooltip's numbers", () => {
		expect(VICTORIES.safeParse({ science: [{ player: 1, progress: 0.5, stages: STAGES }] }).success).toBe(false);
	});
});
