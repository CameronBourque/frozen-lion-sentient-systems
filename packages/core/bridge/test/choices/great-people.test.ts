// Tests for great-people.ts: the schema for the great people the player can recruit or pass.

import { describe, expect, test } from "vitest";
import { GREAT_PEOPLE_CHOICE } from "../../src/choices/great-people.js";

const CHOICE = [
	{ type: "GREAT_PERSON_INDIVIDUAL_ARYABHATA", recruit: true, passCost: 6 },
	{ type: "GREAT_PERSON_INDIVIDUAL_BI_SHENG", recruit: false, passCost: 12 },
];

describe("GREAT_PEOPLE_CHOICE", () => {
	test("accepts the great people to recruit or pass", () => {
		expect(GREAT_PEOPLE_CHOICE.parse(CHOICE)).toEqual(CHOICE);
	});

	test("accepts no great person choice", () => {
		expect(GREAT_PEOPLE_CHOICE.safeParse(undefined).success).toBe(true);
	});

	test("rejects a great person without recruit", () => {
		expect(GREAT_PEOPLE_CHOICE.safeParse([{ type: "GREAT_PERSON_INDIVIDUAL_ARYABHATA" }]).success).toBe(false);
	});
});
