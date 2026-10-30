// Tests for income.ts: the schema for the player's income, expenses, unit upkeep, and gold deals.

import { describe, expect, test } from "vitest";
import { INCOME } from "../../src/state/income.js";

const SECTION = {
	gold: { total: 475.1, cities: 420, deals: 22, envoys: 33 },
	faith: { total: 109, cities: 101, greatPeople: 8 },
	science: { total: 123.5, cities: 123.5 },
	culture: { total: 216.6, cities: 216.6, other: 1 },
	cities: [
		{
			city: { owner: 0, id: 65536 },
			tourism: 18,
			upkeep: 9,
			sources: [
				{ kind: "building", name: "Factory", type: "BUILDING_FACTORY", yields: { production: 3 }, upkeep: 2 },
				{ kind: "route", name: "Bagacum", city: { owner: 0, id: 131073 }, yields: { gold: 4, faith: 1 } },
				{ kind: "district", name: "Encampment", type: "DISTRICT_ENCAMPMENT", upkeep: 1 },
			],
		},
	],
	expenses: { total: 210, cities: 117, units: 88, deals: 5 },
	unitUpkeep: [
		{ type: "UNIT_MUSKETMAN", name: "Musketman", count: 10, gold: 30 },
		{ type: "UNIT_KNIGHT", formation: "CORPS" as const, name: "Knight", count: 1, gold: 5 },
	],
	deals: [{ player: 5, turnsLeft: 15, gold: -5 }],
};

describe("INCOME", () => {
	test("accepts the income, expenses, unit upkeep, and deals", () => {
		expect(INCOME.parse(SECTION)).toEqual(SECTION);
	});

	test("accepts expenses the totals don't cover", () => {
		const section = { ...SECTION, expenses: { ...SECTION.expenses, other: 2 } };

		expect(INCOME.parse(section)).toEqual(section);
	});

	test("rejects a yield without its total", () => {
		expect(INCOME.safeParse({ ...SECTION, gold: { cities: 420 } }).success).toBe(false);
	});

	test("rejects a source of a kind the report doesn't have", () => {
		const city = { ...SECTION.cities[0], sources: [{ kind: "garden", name: "Garden" }] };

		expect(INCOME.safeParse({ ...SECTION, cities: [city] }).success).toBe(false);
	});

	test("rejects a formation that isn't a corps or an army", () => {
		const unit = { ...SECTION.unitUpkeep[0], formation: "STANDARD" };

		expect(INCOME.safeParse({ ...SECTION, unitUpkeep: [unit] }).success).toBe(false);
	});
});
