// Finds yml comments that break the doc path rule in docs/rules/code.md.
// ESLint can't read yml, so this covers the comments in the workflow files.

import { findDocPathProblems } from "../../comment-rules/src/doc-path-rule.mjs";

// YAML starts a comment at a # that begins the line or follows whitespace.
const COMMENT = /(?:^|\s)#(.*)$/;

// Returns one "file:line: message" per doc path in a comment that breaks the
// rule, and the exit code. `docs` says which files exist, as checkDocPath
// describes.
export function checkComments(files, docs) {
	const lines = [];

	for (const [file, text] of Object.entries(files)) {
		text.split(/\r?\n/).forEach((line, index) => {
			const comment = COMMENT.exec(line)?.[1];

			if (comment === undefined) return;

			for (const message of findDocPathProblems(comment, docs)) lines.push(`${file}:${index + 1}: ${message}`);
		});
	}

	return { lines, exitCode: lines.length > 0 ? 1 : 0 };
}
