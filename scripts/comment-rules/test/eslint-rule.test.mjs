// Tests for eslint-rule.mjs: the rule reports comments that break a text rule
// and leaves other comments and code alone.

import { Linter } from "eslint";
import { describe, expect, test } from "vitest";
import commentRules from "../src/eslint-rule.mjs";

const linter = new Linter();
const config = [
	{
		plugins: { "comment-rules": commentRules },
		rules: { "comment-rules/text-rules": "error" },
	},
];

const lint = (code) => linter.verify(code, config);

describe("comment-rules/text-rules", () => {
	test("reports a line comment, at the comment's position", () => {
		const messages = lint("const a = 1;\n// copied from line 12\n");

		expect(messages).toHaveLength(1);
		expect(messages[0]).toMatchObject({ line: 2, column: 1, message: 'comment names "line 12"; name the function and its file instead' });
	});

	test("reports a block comment", () => {
		const messages = lint("/* see lines 3 to 5 */\nconst a = 1;\n");

		expect(messages).toHaveLength(1);
		expect(messages[0].message).toContain('"lines 3"');
	});

	test("reports every comment that breaks the rule", () => {
		expect(lint("// line 1\n// line 2\n")).toHaveLength(2);
	});

	test("lets through a comment that follows the rules", () => {
		expect(lint("// the first line of the file\nconst a = 1;\n")).toEqual([]);
	});

	test("reports a file header over three lines, at the header", () => {
		const messages = lint("// one\n// two\n// three\n// four\n\nconst a = 1;\n");

		expect(messages).toHaveLength(1);
		expect(messages[0]).toMatchObject({ line: 1, message: "file header is 4 lines, over 3" });
	});

	test("lets through a header of three lines and a comment after code", () => {
		expect(lint("// one\n// two\n// three\n\nconst a = 1;\n// four\n// five\n// six\n// seven\n")).toEqual([]);
	});

	test("starts the header after a shebang", () => {
		expect(lint("#!/usr/bin/env node\n// one\n// two\n// three\n\nconst a = 1;\n")).toEqual([]);
	});

	test("reports a file that is only a long comment", () => {
		expect(lint("// one\n// two\n// three\n// four\n")).toHaveLength(1);
	});

	test("lets through code that names a line number", () => {
		expect(lint('const s = "line 12";\n')).toEqual([]);
	});
});
