// Tests for standalone-rule.mjs: a comment block with no code right below it.

import { describe, expect, test } from "vitest";
import { findStandalone } from "../src/standalone-rule.mjs";

const lines = (from, to, text = "") => Array.from({ length: to - from + 1 }, (_, i) => ({ start: from + i, end: from + i, text }));

describe("findStandalone", () => {
	test("lets through a block directly above code", () => {
		expect(findStandalone(lines(5, 6), new Set([1, 7]))).toEqual([]);
	});

	test("fails a block with a blank line before the code", () => {
		expect(findStandalone(lines(5, 6), new Set([1, 8]))).toEqual([
			{ line: 5, message: "comment block stands alone; put it directly above the code it describes" },
		]);
	});

	test("fails a block at the end of a file", () => {
		expect(findStandalone(lines(5, 7), new Set([1]))).toHaveLength(1);
	});

	test("lets through a one-line comment that stands alone", () => {
		expect(findStandalone(lines(5, 5), new Set([1, 9]))).toEqual([]);
	});

	test("joins touching comments into one block", () => {
		expect(findStandalone([{ start: 5, end: 5 }, { start: 6, end: 7 }], new Set([1, 9]))).toEqual([
			{ line: 5, message: "comment block stands alone; put it directly above the code it describes" },
		]);
	});

	test("reports each stray block at its first line", () => {
		expect(findStandalone([...lines(3, 4), ...lines(8, 9)], new Set([1, 6, 11])).map((p) => p.line)).toEqual([3, 8]);
	});

	test("leaves the header to the header rule", () => {
		expect(findStandalone(lines(1, 4), new Set([6]))).toEqual([]);
	});

	test("fails a second block that continues the header after a blank line", () => {
		expect(findStandalone([...lines(1, 2), ...lines(4, 5)], new Set([7]))).toHaveLength(1);
	});

	test("checks a first block that comes after code", () => {
		expect(findStandalone(lines(5, 6), new Set([1, 9]))).toHaveLength(1);
	});

	test("lets through a block that opts out with a reason", () => {
		const spans = [{ start: 5, end: 5, text: " comment-lint-ignore: section label" }, { start: 6, end: 6, text: " more" }];

		expect(findStandalone(spans, new Set([1, 9]))).toEqual([]);
	});

	test("does not let a marker with no reason opt out", () => {
		expect(findStandalone(lines(5, 6, " comment-lint-ignore:"), new Set([1, 9]))).toHaveLength(1);
	});

	test("lets through a file with comments and no code", () => {
		expect(findStandalone(lines(1, 5), new Set())).toEqual([]);
	});
});
