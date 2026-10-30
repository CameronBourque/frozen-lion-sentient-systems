// Tests for great-people.ts: the schema for the great people on offer.

import { describe, expect, test } from "vitest";
import { GREAT_PEOPLE } from "../../src/state/great-people.js";

const SUN_TZU = {
	class: "GREAT_PERSON_CLASS_GENERAL",
	type: "GREAT_PERSON_INDIVIDUAL_SUN_TZU",
	name: "Sun Tzu",
	era: "ERA_CLASSICAL",
	cost: 30,
	passive: "+5 [ICON_Strength] Combat Strength and +1 [ICON_Movement] Movement to Classical and Medieval era land units within 2 tiles.",
	action: { name: "Retire", usage: "Activate at a district or wonder with an available Great Work slot.", effect: "The Art of War ([ICON_GreatWork_Writing] Writing)." },
	patronage: { gold: { cost: 650, can: true }, faith: { cost: 450, can: false } },
	progress: [{ player: 0, points: 4.5, perTurn: 2 }, { unmet: true as const, points: 0, perTurn: 0 }],
};

const THEMISTOCLES = {
	class: "GREAT_PERSON_CLASS_ADMIRAL",
	type: "GREAT_PERSON_INDIVIDUAL_THEMISTOCLES",
	name: "Themistocles",
	era: "ERA_CLASSICAL",
	cost: 30,
	action: { name: "Retire", usage: "Activate on a tile with no military unit.", effect: "Instantly creates a Quadrireme unit.", charges: 1 },
	cantEarn: "You must have a coastal city center or a Harbor district in order to spawn a Great Admiral.",
	progress: [{ player: 0, points: 0, perTurn: 0 }],
};

describe("GREAT_PEOPLE", () => {
	test("accepts great people with patronage, and one the player can't earn", () => {
		expect(GREAT_PEOPLE.parse([SUN_TZU, THEMISTOCLES])).toEqual([SUN_TZU, THEMISTOCLES]);
	});

	test("accepts none on offer", () => {
		expect(GREAT_PEOPLE.safeParse([]).success).toBe(true);
	});

	test("rejects a great person without their progress", () => {
		expect(GREAT_PEOPLE.safeParse([{ ...SUN_TZU, progress: undefined }]).success).toBe(false);
	});
});
