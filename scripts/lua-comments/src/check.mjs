// Finds Lua comments that break the comment rules in docs/rules/code.md.
// ESLint checks the TypeScript and JavaScript comments, and the CI lint job has
// no Lua tool, so this covers the Lua ones.

import { checkHeader } from "../../comment-rules/src/header-rule.mjs";
import { TEXT_RULES } from "../../comment-rules/src/text-rules.mjs";

// The same limit as the comments option of max-len in eslint.config.js.
export const LIMIT = 80;
// The same tab width as the tabWidth option of max-len.
const TAB_WIDTH = 4;

// Returns the width of a line in columns. A tab counts as TAB_WIDTH and a
// character as 1, however many bytes it takes.
export function width(line) {
	return [...line.replaceAll("\t", " ".repeat(TAB_WIDTH))].length;
}

// One entry per rule. find gets a full-line comment and the column limit, and
// returns a message when the comment breaks the rule, or undefined when it
// doesn't. The text rules are shared with the ESLint rule for TypeScript.
export const RULES = [
	{
		name: "line-width",
		find(line, limit) {
			const columns = width(line);

			if (columns > limit) return `comment is ${columns} columns, over ${limit}`;
		},
	},
	...TEXT_RULES,
];

// Returns the line spans of the full-line comments that come before the first
// code in a file, for the header rule.
function leadingComments(lines) {
	const spans = [];

	for (const [index, line] of lines.entries()) {
		if (/^\s*--/.test(line)) spans.push({ start: index + 1, end: index + 1 });
		else if (line.trim() !== "") break;
	}

	return spans;
}

// Returns one "file:line: message" per problem in a full-line comment or file
// header, and the exit code. A comment after code on the same line isn't
// checked.
export function checkComments(files, limit = LIMIT) {
	const lines = [];

	for (const [file, text] of Object.entries(files)) {
		const fileLines = text.split(/\r?\n/);
		const header = checkHeader(leadingComments(fileLines));

		if (header) lines.push(`${file}:${header.line}: ${header.message}`);

		fileLines.forEach((line, index) => {
			if (!/^\s*--/.test(line)) return;

			for (const rule of RULES) {
				const message = rule.find(line, limit);

				if (message) lines.push(`${file}:${index + 1}: ${message}`);
			}
		});
	}

	return { lines, exitCode: lines.length > 0 ? 1 : 0 };
}
