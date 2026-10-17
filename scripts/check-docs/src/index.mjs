// Checks the mechanical parts of docs/rules/docs.md and docs/rules/writing.md.
// Usage: node scripts/check-docs/src/index.mjs
// Prints one line per problem as file:line: rule: message, and exits 1 if there are any.
// This file only reads and prints. run.mjs holds the logic, so tests can reach it.

import { execFileSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { runChecks } from "./run.mjs";

const root = path.resolve(import.meta.dirname, "../../..");

// Committed files plus new files that git doesn't ignore. Git applies .gitignore
// and .git/info/exclude, so local-only docs are skipped.
const paths = execFileSync("git", ["ls-files", "-z", "--cached", "--others", "--exclude-standard"], { cwd: root, encoding: "utf8" })
	.split("\0")
	.filter((p) => p && fs.existsSync(path.join(root, p)));

const files = Object.fromEntries(paths.map((p) => [p, p.endsWith(".md") ? fs.readFileSync(path.join(root, p), "utf8") : null]));
const { lines, exitCode } = runChecks(files);

for (const line of lines) console.log(line);

process.exitCode = exitCode;
