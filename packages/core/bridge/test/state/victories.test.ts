// Tests for victories.ts: the schema for the progress toward each victory.

import { describe, expect, test } from "vitest";
import { VICTORIES } from "../../src/state/victories.js";

const SCIENCE = [
	{ player: 1, progress: 0.5, techs: 20, sciencePerTurn: 8 },
	{ unmet: true as const },
];

describe("VICTORIES", () => {
	test("accepts a player and one that has not been met", () => {
		expect(VICTORIES.parse({ science: SCIENCE })).toEqual({ science: SCIENCE });
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
		expect(VICTORIES.safeParse({ science: [{ player: 1, progress: 0.5 }] }).success).toBe(false);
	});
});
