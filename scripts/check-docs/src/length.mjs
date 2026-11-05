// Check 5: warn, without failing, on files over 150 lines, on lines over 300
// characters, and on files over 12,000 characters.

import path from "node:path";
import { problem } from "./parse.mjs";

export const MAX_LINES = 150;
export const MAX_LINE_LENGTH = 300;
export const MAX_FILE_LENGTH = 12000;

// release-please writes the changelogs from commit subjects.
const isChangelog = (doc) => path.posix.basename(doc.path) === "CHANGELOG.md";

const count = (n) => n.toLocaleString("en-US");

const warning = (doc, line, message) => ({ ...problem(doc.path, line, "length", message), warning: true });

export function checkLength(repo) {
	return [...repo.docs.values()].filter((doc) => !isChangelog(doc)).flatMap((doc) => [...fileWarnings(doc), ...lineWarnings(doc)]);
}

function fileWarnings(doc) {
	const warnings = [];
	const characters = doc.lines.join("\n").length;

	if (doc.lines.length > MAX_LINES) warnings.push(warning(doc, MAX_LINES + 1, `${doc.lines.length} lines. Aim for under ${MAX_LINES}`));

	if (characters > MAX_FILE_LENGTH) {
		warnings.push(warning(doc, 1, `${count(characters)} characters. Keep files to ${count(MAX_FILE_LENGTH)} and split by topic`));
	}

	return warnings;
}

// Lines in fenced code blocks are skipped, because code can't wrap. parse.mjs
// empties those lines in `text`.
function lineWarnings(doc) {
	return doc.lines.flatMap((line, i) => {
		const inCode = doc.text[i] === "" && line !== "";

		if (inCode || line.length <= MAX_LINE_LENGTH) return [];

		return [warning(doc, i + 1, `line of ${line.length} characters. Keep lines to ${MAX_LINE_LENGTH}`)];
	});
}
