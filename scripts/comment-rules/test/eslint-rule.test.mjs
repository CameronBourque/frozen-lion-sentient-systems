// Tests for eslint-rule.mjs: the rule reports comments that break a text rule
// and leaves other comments and code alone.

import { Linter } from "eslint";
import { describe, expect, test } from "vitest";
import commentRules, { docPathsRule } from "../src/eslint-rule.mjs";

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
		expect(lint("// one\n// two\n// three\n\nconst a = 1;\n// four\n// five\n// six\n// seven\nconst b = 2;\n")).toEqual([]);
	});

	test("starts the header after a shebang", () => {
		expect(lint("#!/usr/bin/env node\n// one\n// two\n// three\n\nconst a = 1;\n")).toEqual([]);
	});

	test("reports a file that is only a long comment", () => {
		expect(lint("// one\n// two\n// three\n// four\n")).toHaveLength(1);
	});

	test("lets through a comment that opts out with a reason", () => {
		expect(lint("const a = 1;\n// line 12 comment-lint-ignore: quotes an error\n")).toEqual([]);
	});

	test("reports a comment that opts out with no reason", () => {
		expect(lint("const a = 1;\n// line 12 comment-lint-ignore:\n")).toHaveLength(1);
	});

	test("lets through code that names a line number", () => {
		expect(lint('const s = "line 12";\n')).toEqual([]);
	});

	test("reports a comment block that stands alone, at its first line", () => {
		const messages = lint("// one\n\nconst a = 1;\n\n// two\n// three\n\nconst b = 2;\n");

		expect(messages).toHaveLength(1);
		expect(messages[0]).toMatchObject({ line: 5, message: "comment block stands alone; put it directly above the code it describes" });
	});

	test("reports a header that continues in a second block", () => {
		expect(lint("// one\n// two\n\n// three\n// four\nconst a = 1;\n\n// five\n// six\n\nconst b = 2;\n")).toHaveLength(1);
	});

	test("reports a block comment that stands alone", () => {
		expect(lint("const a = 1;\n\n/*\n * one\n */\n\nconst b = 2;\n")).toHaveLength(1);
	});

	test("lets through a block directly above code, and a one-line comment alone", () => {
		expect(lint("const a = 1;\n\n// one\n// two\nconst b = 2;\n\n// section\n\nconst c = 3;\n")).toEqual([]);
	});

	test("does not count a comment that follows code on its line as a block", () => {
		expect(lint("const a = 1; // one\n// two\n\nconst b = 2;\n")).toEqual([]);
	});

	test("lets through a standalone block that opts out with a reason", () => {
		expect(lint("const a = 1;\n\n// comment-lint-ignore: section\n// more\n\nconst b = 2;\n")).toEqual([]);
	});
});

describe("comment-rules/doc-paths", () => {
	const files = new Set(["docs/findings/game-api.md"]);
	const docLinter = new Linter();
	const docConfig = [
		{
			plugins: { "comment-rules": { rules: { "doc-paths": docPathsRule({ exists: (p) => files.has(p) }) } } },
			rules: { "comment-rules/doc-paths": "error" },
		},
	];
	const lintDocs = (code) => docLinter.verify(code, docConfig);

	test("reports a path that doesn't exist, at the comment's position", () => {
		const messages = lintDocs("const a = 1;\n// see docs/findings/old.md\n");

		expect(messages).toHaveLength(1);
		expect(messages[0]).toMatchObject({ line: 2, column: 1, message: "docs/findings/old.md does not exist" });
	});

	test("reports a path in a block comment", () => {
		expect(lintDocs("/* see docs/findings/old.md */\nconst a = 1;\n")).toHaveLength(1);
	});

	test("lets through a path that exists, a planned path, and code", () => {
		expect(lintDocs("// see docs/findings/game-api.md\n// and docs/reference/tools.md*\nconst s = 'docs/findings/old.md';\n")).toEqual([]);
	});

	test("reports a planned path that exists", () => {
		expect(lintDocs("// see docs/findings/game-api.md*\n")).toHaveLength(1);
	});

	test("is part of the plugin, with the real docs", () => {
		const real = new Linter();
		const config = [{ plugins: { "comment-rules": commentRules }, rules: { "comment-rules/doc-paths": "error" } }];

		expect(real.verify("// see docs/findings/game-api.md\n", config)).toEqual([]);
		expect(real.verify("// see docs/findings/old.md\n", config)).toHaveLength(1);
	});
});
