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

	test("lets through a comment that opts out with a reason", () => {
		const text = "local x = 1\n-- line 12 comment-lint-ignore: quotes an error\n";

		expect(checkComments({ "a.lua": text }).lines).toEqual([]);
	});

	test("lets through code that names a line number", () => {
		expect(checkComments({ "a.lua": 'local s = "line 12"\n' }).lines).toEqual([]);
	});

	test("names the line of a file header over three lines", () => {
		const { lines, exitCode } = checkComments({ "a.lua": "\n-- 1\n-- 2\n-- 3\n-- 4\n\nlocal x = 1\n" });

		expect(lines).toEqual(["a.lua:2: file header is 4 lines, over 3"]);
		expect(exitCode).toBe(1);
	});

	test("lets through a header at three lines and comments after code", () => {
		const text = "-- 1\n-- 2\n-- 3\n\nlocal x = 1\n-- 4\n-- 5\n-- 6\n-- 7\n";

		expect(checkComments({ "a.lua": text }).lines).toEqual([]);
	});

	test("ends the header at a blank line", () => {
		expect(checkComments({ "a.lua": "-- 1\n-- 2\n\n-- 3\n-- 4\nlocal x\n" }).lines).toEqual([]);
	});

	test("checks every file", () => {
		const { lines } = checkComments({ "a.lua": overLimit, "b.lua": overLimit });

		expect(lines).toHaveLength(2);
	});
});

describe("doc paths", () => {
	const files = new Set(["docs/findings/game-api.md"]);
	const docs = { exists: (p) => files.has(p) };

	test("reports a path that doesn't exist", () => {
		const { lines, exitCode } = checkComments({ "a.lua": "local x = 1\n-- see docs/findings/old.md\n" }, undefined, docs);

		expect(lines).toEqual(["a.lua:2: docs/findings/old.md does not exist"]);
		expect(exitCode).toBe(1);
	});

	test("lets through a path that exists and a planned path", () => {
		expect(checkComments({ "a.lua": "-- see docs/findings/game-api.md\n-- and docs/reference/tools.md*\n" }, undefined, docs).lines).toEqual([]);
	});

	test("skips the rule when no docs are given", () => {
		expect(checkComments({ "a.lua": "-- see docs/findings/old.md\n" }).lines).toEqual([]);
	});
});
