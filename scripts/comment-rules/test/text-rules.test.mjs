// Tests for text-rules.mjs: each rule catches a comment and lets one through.

import { describe, expect, test } from "vitest";
import { TEXT_RULES } from "../src/text-rules.mjs";

const rule = (name) => TEXT_RULES.find((r) => r.name === name);

describe("line-number", () => {
	const { find } = rule("line-number");

	test.each([
		["a line", "-- copied from line 12 of the game file", "line 12"],
		["a range", "// see lines 3 to 5", "lines 3"],
		["any case", "-- Line 7 sets the flag", "Line 7"],
	])("catches %s", (_, comment, named) => {
		expect(find(comment)).toContain(`"${named}"`);
	});

	test.each([
		["no number", "-- the first line of the file"],
		["a number without line", "-- retry 3 times"],
		["a word that ends in line", "-- the pipeline 3 steps long"],
		["a function name", "-- copied from GetPlayerData in Player.lua"],
	])("lets through %s", (_, comment) => {
		expect(find(comment)).toBeUndefined();
	});
});

describe("TEXT_RULES", () => {
	test("gives every rule a unique name", () => {
		const names = TEXT_RULES.map((r) => r.name);

		expect(new Set(names).size).toBe(names.length);
	});
});
