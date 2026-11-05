// The doc path rule, shared by the Lua check and the ESLint rule: a path to a
// doc in a comment must point to a doc that exists. A path with a trailing * is
// a doc that isn't written yet. check-docs applies the same rule to Markdown.

import fs from "node:fs";
import path from "node:path";
import { parse } from "../../check-docs/src/parse.mjs";
import { checkDocPath, findDocPaths } from "../../doc-paths/src/doc-paths.mjs";

// Returns the messages for the doc paths in the text of one comment that
// break the rule. `docs` says which files exist, as checkDocPath describes.
export function findDocPathProblems(text, docs) {
	return findDocPaths(text).map((ref) => checkDocPath(ref, docs)).filter(Boolean);
}

// Reads the docs from the files under the repo root.
export function repoDocs(root) {
	const anchors = new Map();

	return {
		exists: (file) => fs.existsSync(path.join(root, file)),
		anchors(file) {
			if (!anchors.has(file)) anchors.set(file, parse(file, fs.readFileSync(path.join(root, file), "utf8")).anchors);

			return anchors.get(file);
		},
	};
}
