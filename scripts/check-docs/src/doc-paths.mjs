// Check 6: a path to a doc in backticks or in link text must point to a doc
// that exists. A path with a trailing * is a doc that isn't written yet. The
// comment rules apply the same rule to code comments.

import { checkDocPath, findDocPaths } from "../../doc-paths/src/doc-paths.mjs";
import { problem } from "./parse.mjs";

const codeSpan = /(`+)(.+?)\1/g;
const linkText = /\[([^\]]+)\]\(/g;

export function checkDocPaths(repo) {
	const context = {
		exists: (p) => repo.files.has(p),
		anchors: (p) => repo.docs.get(p)?.anchors,
	};
	const problems = [];

	for (const doc of repo.docs.values()) {
		doc.lines.forEach((line, i) => {
			// Lines in a code block are empty in doc.text, so they are skipped.
			if (doc.text[i] === "") return;

			// doc.text has the code spans blanked, so the link text is what is
			// left, and each path is read once.
			const texts = [...line.matchAll(codeSpan)].map((match) => match[2]);

			texts.push(...[...doc.text[i].matchAll(linkText)].map((match) => match[1]));

			for (const text of texts) {
				for (const ref of findDocPaths(text)) {
					const message = checkDocPath(ref, context);

					if (message) problems.push(problem(doc.path, i + 1, "doc-path", message));
				}
			}
		});
	}

	return problems;
}
