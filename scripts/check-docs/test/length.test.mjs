// Tests for length.mjs, check 5.

import { describe, expect, test } from "vitest";
import { checkLength, MAX_FILE_LENGTH, MAX_LINE_LENGTH, MAX_LINES } from "../src/length.mjs";
import { buildRepo } from "../src/parse.mjs";
import { lines, messages, textOfLength } from "./helpers.mjs";

const check = (files) => messages(checkLength(buildRepo(files)));

describe("length", () => {
	test("warns only over the line count", () => {
		expect(checkLength(buildRepo({ "docs/a.md": textOfLength(MAX_LINES) }))).toEqual([]);

		const [warning] = checkLength(buildRepo({ "docs/a.md": textOfLength(MAX_LINES + 1) }));

		expect(warning.warning).toBe(true);
		expect(warning.line).toBe(MAX_LINES + 1);
	});

	test("warns only on a line over the line length", () => {
		expect(check({ "docs/a.md": lines("a".repeat(MAX_LINE_LENGTH)) })).toEqual([]);
		expect(check({ "docs/a.md": lines("Short.", "a".repeat(MAX_LINE_LENGTH + 1)) })).toEqual([
			"docs/a.md:2: length: line of 301 characters. Keep lines to 300",
		]);
	});

	test("skips long lines in fenced code", () => {
		expect(check({ "docs/a.md": lines("```", "a".repeat(MAX_LINE_LENGTH + 1), "```") })).toEqual([]);
	});

	test("counts a long line of inline code", () => {
		const code = "`" + "a".repeat(MAX_LINE_LENGTH) + "`";

		expect(check({ "docs/a.md": lines(code) })).toEqual(["docs/a.md:1: length: line of 302 characters. Keep lines to 300"]);
	});

	test("leaves link targets out of the line length", () => {
		const link = `[a](${"b".repeat(MAX_LINE_LENGTH)})`;

		expect(check({ "docs/a.md": lines(link) })).toEqual([]);
		expect(check({ "docs/a.md": lines("a".repeat(MAX_LINE_LENGTH) + link) })).toEqual([
			"docs/a.md:1: length: line of 303 characters. Keep lines to 300",
		]);
	});

	test("counts a link target inside a code span", () => {
		const code = "`a](" + "b".repeat(MAX_LINE_LENGTH) + ")`";

		expect(check({ "docs/a.md": lines(code) })).toEqual(["docs/a.md:1: length: line of 306 characters. Keep lines to 300"]);
	});

	test("counts link targets in the file length", () => {
		const row = `[a](${"b".repeat(95)})`;
		const text = Array.from({ length: MAX_FILE_LENGTH / 100 + 1 }, () => row).join("\n");

		expect(check({ "docs/a.md": text })).toEqual(["docs/a.md:1: length: 12,220 characters. Keep files to 12,000 and split by topic"]);
	});

	test("warns only over the file length", () => {
		// 120 rows of 99 characters and 119 newlines, plus one, make 12,000.
		const fits = Array.from({ length: MAX_FILE_LENGTH / 100 }, () => "a".repeat(99)).join("\n") + "a";

		expect(check({ "docs/a.md": fits })).toEqual([]);
		expect(check({ "docs/a.md": fits + "a" })).toEqual([
			"docs/a.md:1: length: 12,001 characters. Keep files to 12,000 and split by topic",
		]);
	});

	test("skips changelogs", () => {
		expect(check({ "packages/a/CHANGELOG.md": lines("a".repeat(MAX_LINE_LENGTH + 1)) })).toEqual([]);
	});
});
