// Tests for check.mjs: the width of a line, the comments over the limit, and
// that the shared text rules run on Lua comments.

import { describe, expect, test } from "vitest";
import { checkComments, LIMIT, width } from "../src/check.mjs";

const atLimit = `-- ${"a".repeat(LIMIT - 3)}`;
const overLimit = `${atLimit}a`;

describe("width", () => {
	test("counts a tab as 4 columns", () => {
		expect(width("\t-- a")).toBe(8);
	});

	test("counts a character as 1, not its bytes", () => {
		expect(width("-- é")).toBe(4);
	});
});

describe("checkComments", () => {
	test("lets through a comment at the limit", () => {
		expect(checkComments({ "a.lua": atLimit })).toEqual({ lines: [], exitCode: 0 });
	});

	test("names the file, line, and width of a comment over the limit", () => {
		const { lines, exitCode } = checkComments({ "a.lua": `local x = 1\n${overLimit}\n` });

		expect(lines).toEqual([`a.lua:2: comment is ${LIMIT + 1} columns, over ${LIMIT}`]);
		expect(exitCode).toBe(1);
	});

	test("counts the indent of an indented comment", () => {
		const { lines } = checkComments({ "a.lua": `\t${atLimit}` });

		expect(lines).toHaveLength(1);
	});

	test("reads Windows line endings", () => {
		const { lines } = checkComments({ "a.lua": `${atLimit}\r\n${overLimit}\r\n` });

		expect(lines).toHaveLength(1);
	});

	test("lets through a long line of code, and a comment after code", () => {
		const code = `local x = "${"a".repeat(LIMIT)}"`;

		expect(checkComments({ "a.lua": `${code}\nlocal y = 1 ${overLimit}\n` }).lines).toEqual([]);
	});

	test("applies the shared text rules to a comment", () => {
		const { lines, exitCode } = checkComments({ "a.lua": "local x = 1\n-- copied from line 12\n" });

		expect(lines).toEqual(['a.lua:2: comment names "line 12"; name the function and its file instead']);
		expect(exitCode).toBe(1);
	});

	test("lets through code that names a line number", () => {
		expect(checkComments({ "a.lua": 'local s = "line 12"\n' }).lines).toEqual([]);
	});

	test("checks every file", () => {
		const { lines } = checkComments({ "a.lua": overLimit, "b.lua": overLimit });

		expect(lines).toHaveLength(2);
	});
});
