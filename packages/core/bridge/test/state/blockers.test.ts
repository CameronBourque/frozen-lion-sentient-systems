// Tests for blockers.ts: the schema for the end-turn blockers and the units that need orders.

import { describe, expect, test } from "vitest";
import { BLOCKERS } from "../../src/state/blockers.js";

const BLOCKED = {
	list: [{ type: "ENDTURN_BLOCKING_RESEARCH", choice: "techs" }, { type: "ENDTURN_BLOCKING_UNITS" }],
	units: [196608],
};

describe("BLOCKERS", () => {
	test("accepts blockers with and without a choice, and units", () => {
		expect(BLOCKERS.parse(BLOCKED)).toEqual(BLOCKED);
	});

	test("accepts empty lists, when nothing blocks", () => {
		expect(BLOCKERS.safeParse({ list: [], units: [] }).success).toBe(true);
	});

	test("rejects a blocker without a type", () => {
		expect(BLOCKERS.safeParse({ ...BLOCKED, list: [{ choice: "techs" }] }).success).toBe(false);
	});

	test("rejects a unit that isn't an ID", () => {
		expect(BLOCKERS.safeParse({ ...BLOCKED, units: ["UNIT_SCOUT"] }).success).toBe(false);
	});
});
