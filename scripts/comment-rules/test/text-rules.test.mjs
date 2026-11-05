// Tests for text-rules.mjs: each rule catches a comment and lets one through.

import { describe, expect, test } from "vitest";
import { findText, TEXT_RULES } from "../src/text-rules.mjs";

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

describe("example", () => {
	const { find } = rule("example");

	test.each([
		["such as a quote", '-- has a type such as "?1" and a status'],
		["for example a code span", "// for example `npm run state`, which prints it"],
		["for instance a quote", '-- for instance "Lua" is a proper noun'],
		["any case", '-- Such as "this"'],
	])("catches %s", (_, comment) => {
		expect(find(comment)).toContain("test");
	});

	test.each([
		["such as a name", "-- a district type, such as DISTRICT_CAMPUS, goes in"],
		["no phrase", '-- the "units" field holds the list'],
		["a quote in a later sentence", '-- a stance, such as fortify. It says "done"'],
		["a phrase with nothing after it", "-- a kind of unit, such as"],
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

describe("findText", () => {
	const broken = "-- copied from line 12";

	test("returns the message of every rule a comment breaks", () => {
		expect(findText('-- line 12 holds {"id": 1}')).toHaveLength(2);
	});

	test("returns nothing for a comment that follows the rules", () => {
		expect(findText("-- the first line")).toEqual([]);
	});

	test("skips a comment that opts out with a reason", () => {
		expect(findText(`${broken} comment-lint-ignore: quotes an error`)).toEqual([]);
	});

	test("does not skip an opt-out with no reason", () => {
		expect(findText(`${broken} comment-lint-ignore:`)).toHaveLength(1);
		expect(findText(`${broken} comment-lint-ignore:   `)).toHaveLength(1);
	});
});
