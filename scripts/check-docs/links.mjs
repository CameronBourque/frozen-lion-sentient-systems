// Check 1: every relative link points to a file or folder in the repo, and every
// #anchor matches a heading in the file it points to.

import path from "node:path";
import { problem, resolveLink } from "./parse.mjs";

export function checkLinks(repo) {
	const problems = [];
	for (const doc of repo.docs.values()) {
		for (const link of doc.links) {
			const target = resolveLink(doc.path, link.target);
			if (!target) continue; // External link.

			const isFolder = repo.dirs.has(target.path);
			if (!isFolder && !repo.files.has(target.path)) {
				problems.push(problem(doc.path, link.line, "link", `${link.target} does not exist`));
				continue;
			}

			if (target.anchor === undefined) continue;

			// A link to a folder shows its README, so the anchor is in the README.
			const anchorDoc = repo.docs.get(isFolder ? path.posix.join(target.path, "README.md") : target.path);
			if (!anchorDoc) continue; // Only Markdown headings are checked.
			
			if (!anchorDoc.anchors.has(target.anchor.toLowerCase())) {
				problems.push(problem(doc.path, link.line, "link", `#${target.anchor} is not a heading in ${anchorDoc.path}`));
			}
		}
	}
	return problems;
}
