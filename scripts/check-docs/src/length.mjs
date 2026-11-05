// Check 5: fail on lines over 300 characters, not counting link targets, and
// on files over 12,000 characters. Warn, without failing, on files over 150
// lines.

import path from "node:path";
import { problem } from "./parse.mjs";

export const MAX_LINES = 150;
export const MAX_LINE_LENGTH = 300;
export const MAX_FILE_LENGTH = 12000;

// release-please writes the changelogs from commit subjects.
const isChangelog = (doc) => path.posix.basename(doc.path) === "CHANGELOG.md";

const count = (n) => n.toLocaleString("en-US");

const failure = (doc, line, message) => problem(doc.path, line, "length", message);
const warning = (doc, line, message) => ({ ...failure(doc, line, message), warning: true });

export function checkLength(repo) {
	return [...repo.docs.values()].filter((doc) => !isChangelog(doc)).flatMap((doc) => [...fileProblems(doc), ...lineProblems(doc)]);
}

function fileProblems(doc) {
	const problems = [];
	const characters = doc.lines.join("\n").length;

	if (doc.lines.length > MAX_LINES) problems.push(warning(doc, MAX_LINES + 1, `${doc.lines.length} lines. Aim for under ${MAX_LINES}`));

	if (characters > MAX_FILE_LENGTH) {
		problems.push(failure(doc, 1, `${count(characters)} characters. Keep files to ${count(MAX_FILE_LENGTH)} and split by topic`));
	}

	return problems;
}

const linkTarget = /\]\([^)]*\)/g; // The "(target)" after a link's "]".

// A line's length as a reader sees it, without its link targets. The targets
// still count toward the file length, because an agent reads them.
// `text` has code spans blanked, so a "](" inside code isn't a link.
function visibleLength(line, text) {
	let hidden = 0;

	for (const match of text.matchAll(linkTarget)) hidden += match[0].length - 1;

	return line.length - hidden;
}

// Lines in fenced code blocks are skipped, because code can't wrap. parse.mjs
// empties those lines in `text`.
function lineProblems(doc) {
	return doc.lines.flatMap((line, i) => {
		const inCode = doc.text[i] === "" && line !== "";
		const length = visibleLength(line, doc.text[i]);

		if (inCode || length <= MAX_LINE_LENGTH) return [];

		return [failure(doc, i + 1, `line of ${length} characters. Keep lines to ${MAX_LINE_LENGTH}`)];
	});
}
