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

describe("json-shape", () => {
	const { find } = rule("json-shape");

	test.each([
		["an object that opens with a key", '-- returns {"id": 1, "name": "x"}'],
		["an object with spaces", '// the reply is { "units": [] }'],
		["a quoted key before a colon", '// sends "playerId": the player to act for'],
		["a key with a dash", '-- "city-id" : the city'],
	])("catches %s", (_, comment) => {
		expect(find(comment)).toContain("zod schema");
	});

	test.each([
		["a quoted word", '-- the "units" field holds the list'],
		["a colon in prose", "-- note: the game rounds down"],
		["a brace without a key", "-- a table like { x, y }"],
		["a quote then a colon far apart", '-- say "hi" and then: wait'],
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
