// Finds paths to docs in a line of text and checks that each one exists. The
// Markdown check and the comment rules share it. Nothing here reads the disk,
// so the caller says which files exist. The rules are in docs/rules/docs.md.

// A doc path starts with docs/ or findings/ and ends in .md. The lookbehind
// skips a path inside a longer one, such as packages/x/docs/a.md. A trailing *
// marks a doc that isn't written yet.
const DOC_PATH = /(?<![\w./~-])((?:docs|findings)\/[\w/.-]*\.md)(?:#([\w-]+))?(\*)?/g;

// A path without a docs/ prefix is also tried under docs/.
const ROOTS = ["", "docs/"];

// Returns each doc path in the text as { raw, path, anchor, planned }, where
// raw is the text as written.
export function findDocPaths(text) {
	return [...text.matchAll(DOC_PATH)].map((match) => ({
		raw: match[0],
		path: match[1],
		anchor: match[2],
		planned: match[3] === "*",
	}));
}

// Returns the message for a path that breaks the rules, or undefined when it is
// fine. `exists(path)` says whether a repo file exists. `anchors(path)` returns
// the heading anchors of a Markdown file, or undefined when they are unknown.
export function checkDocPath(ref, { exists, anchors = () => undefined }) {
	if (ref.planned) return checkPlanned(ref, exists);

	const found = ROOTS.map((root) => root + ref.path).find(exists);

	if (!found) return `${ref.raw} does not exist`;

	if (ref.anchor !== undefined && anchors(found) && !anchors(found).has(ref.anchor.toLowerCase())) {
		return `#${ref.anchor} is not a heading in ${found}`;
	}
}

// A planned path is written from docs/ to say where the file will go, and the
// file must not exist yet.
function checkPlanned(ref, exists) {
	if (!ref.path.startsWith("docs/")) return `${ref.raw} is planned, so write its path from docs/`;

	if (exists(ref.path)) return `${ref.raw} exists, so remove the *`;
}
