// Checks the mechanical parts of docs/rules/docs.md and docs/rules/writing.md.
// Usage: node scripts/check-docs/index.mjs
// Prints one line per problem as file:line: rule: message, and exits 1 if there are any.

import { execFileSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { buildRepo } from "./parse.mjs";
import { checkLinks } from "./links.mjs";
import { checkIndexes } from "./indexes.mjs";
import { checkSections } from "./sections.mjs";
import { checkWriting } from "./writing.mjs";
import { checkLength } from "./length.mjs";

const root = path.resolve(import.meta.dirname, "../..");

// Committed files plus new files that git doesn't ignore. Git applies .gitignore
// and .git/info/exclude, so local-only docs are skipped.
const paths = execFileSync("git", ["ls-files", "-z", "--cached", "--others", "--exclude-standard"], { cwd: root, encoding: "utf8" })
	.split("\0")
	.filter((p) => p && fs.existsSync(path.join(root, p)));

const files = Object.fromEntries(paths.map((p) => [p, p.endsWith(".md") ? fs.readFileSync(path.join(root, p), "utf8") : null]));
const repo = buildRepo(files);

const results = [checkLinks, checkIndexes, checkSections, checkWriting, checkLength].flatMap((check) => check(repo));
const warnings = results.filter((r) => r.warning);
const problems = results.filter((r) => !r.warning);

const format = (r) => `${r.file}:${r.line}: ${r.rule}: ${r.message}`;
for (const warning of warnings) console.log(`${format(warning)} (warning)`);
for (const p of problems) console.log(format(p));

if (problems.length > 0) {
	console.log(`\n${problems.length} problem${problems.length === 1 ? "" : "s"} in ${repo.docs.size} files.`);
	process.exit(1);
}
console.log(`Checked ${repo.docs.size} files. No problems.`);
