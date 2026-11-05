// Tests for header-rule.mjs: the length of the first comment run in a file.

import { describe, expect, test } from "vitest";
import { checkHeader, HEADER_LIMIT } from "../src/header-rule.mjs";

const lines = (from, to) => Array.from({ length: to - from + 1 }, (_, i) => ({ start: from + i, end: from + i }));

describe("checkHeader", () => {
	test("lets through no comments", () => {
		expect(checkHeader([])).toBeUndefined();
	});

	test("lets through a header at the limit", () => {
		expect(checkHeader(lines(1, HEADER_LIMIT))).toBeUndefined();
	});

	test("names the start and length of a header over the limit", () => {
		expect(checkHeader(lines(1, HEADER_LIMIT + 1))).toEqual({
			line: 1,
			message: `file header is ${HEADER_LIMIT + 1} lines, over ${HEADER_LIMIT}`,
		});
	});

	test("counts every line of a block comment", () => {
		expect(checkHeader([{ start: 2, end: 6 }])).toEqual({ line: 2, message: "file header is 5 lines, over 3" });
	});

	test("ends the header at a blank line", () => {
		expect(checkHeader([...lines(1, 2), ...lines(4, 6)])).toBeUndefined();
	});

	test("joins comments with no blank line between them", () => {
		expect(checkHeader([{ start: 1, end: 2 }, { start: 3, end: 4 }])?.message).toBe("file header is 4 lines, over 3");
	});
});
