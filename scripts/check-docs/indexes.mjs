// Check 2: every folder under docs/ has a README.md, and the README links every
// Markdown file and subfolder in that folder.

import path from "node:path";
import { problem, resolveLink } from "./parse.mjs";

const posix = path.posix;

export function checkIndexes(repo) {
	const folders = foldersWithDocs(repo);
	const problems = [];

	for (const folder of folders) {
		const readme = repo.docs.get(`${folder}/README.md`);

		if (!readme) {
			problems.push(problem(folder, 1, "index", "folder has no README.md"));
			continue;
		}

		const linked = new Set(readme.links.map((link) => resolveLink(readme.path, link.target)?.path));

		for (const child of childrenOf(folder, repo, folders)) {
			if (linked.has(child.path) || linked.has(`${child.path}/README.md`)) continue;

			const name = posix.basename(child.path) + (child.isFolder ? "/" : "");

			problems.push(problem(readme.path, 1, "index", `${name} is not linked from this index`));
		}
	}

	return problems;
}

// docs/ and every folder under it that holds a Markdown file at any depth.
function foldersWithDocs(repo) {
	const folders = new Set();

	for (const docPath of repo.docs.keys()) {
		for (let dir = posix.dirname(docPath); dir === "docs" || dir.startsWith("docs/"); dir = posix.dirname(dir)) folders.add(dir);
	}

	return [...folders].sort();
}

function childrenOf(folder, repo, folders) {
	const files = [...repo.docs.keys()]
		.filter((p) => posix.dirname(p) === folder && posix.basename(p) !== "README.md")
		.map((p) => ({ path: p, isFolder: false }));
	const subfolders = folders.filter((dir) => posix.dirname(dir) === folder).map((dir) => ({ path: dir, isFolder: true }));

	return [...files, ...subfolders];
}
