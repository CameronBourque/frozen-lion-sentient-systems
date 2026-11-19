// Tests for check.mjs: which strings count as patterns, and which classes in
// them break the rule.

import { describe, expect, test } from "vitest";
import { checkPatterns, findClasses } from "../src/check.mjs";

describe("findClasses", () => {
	test("finds a class in a pattern passed to a string function", () => {
		expect(findClasses(`local word = text:match("^%s*(%a+)")`)).toEqual(["s"]);
		expect(findClasses(`for word in text:gmatch('%w+') do`)).toEqual(["w"]);
		expect(findClasses(`string.find(text, "%D")`)).toEqual(["D"]);
		expect(findClasses(`text:gsub("[%c]", "")`)).toEqual(["c"]);
	});

	test("finds a class in a pattern held in a variable", () => {
		expect(findClasses(`local pattern = "^(%d+) from "`)).toEqual(["d"]);
	});

	test("finds one class in each string", () => {
		expect(findClasses(`text:find("%s", 1) or text:find("%p")`)).toEqual(["s", "p"]);
	});

	test("skips an escaped percent sign, sets, and other escapes", () => {
		expect(findClasses(`text:gsub("%%a", "")`)).toEqual([]);
		expect(findClasses(`text:gsub("%%%a", "")`)).toEqual(["a"]);
		expect(findClasses(`text:match("^[%+%-]?[" .. CHARS.digit .. "%.,]+")`)).toEqual([]);
		expect(findClasses(`text:gsub("(x)", "%1")`)).toEqual([]);
	});

	test("skips a format and a full-line comment", () => {
		expect(findClasses(`local text = string.format("%d at %s", x, y)`)).toEqual([]);
		expect(findClasses(`-- text:match("%a+")`)).toEqual([]);
	});
});

describe("checkPatterns", () => {
	test("names the file, line, and class", () => {
		const { lines, exitCode } = checkPatterns({ "a.lua": `local x = 1\r\nreturn text:match("%a")\r\n` });

		expect(lines).toEqual(["a.lua:2: %a matches by the game's code page and splits UTF-8 text. Use a set from SENTIENTSYSTEMS_CHARS. See docs/findings/lua/patterns.md"]);
		expect(exitCode).toBe(1);
	});

	test("passes files with no classes", () => {
		expect(checkPatterns({ "a.lua": `return text:match("[" .. SENTIENTSYSTEMS_CHARS.space .. "]")\n` })).toEqual({ lines: [], exitCode: 0 });
	});
});
