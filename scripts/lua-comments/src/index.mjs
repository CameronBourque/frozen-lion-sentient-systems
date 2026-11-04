// Checks that no full-line comment in the repo's Lua files is over 80 columns.
// Usage: node scripts/lua-comments/src/index.mjs Prints one line per problem as
// file:line: message, and exits 1 if there are any. This file only reads and
// prints. check.mjs holds the logic, so tests can reach it.

import { execFileSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { checkComments } from "./check.mjs";

const root = path.resolve(import.meta.dirname, "../../..");

// Committed files plus new files that git doesn't ignore, as check-docs lists
// them.
const paths = execFileSync("git", ["ls-files", "-z", "--cached", "--others", "--exclude-standard", "*.lua"], { cwd: root, encoding: "utf8" })
	.split("\0")
	.filter((p) => p && fs.existsSync(path.join(root, p)));

const files = Object.fromEntries(paths.map((p) => [p, fs.readFileSync(path.join(root, p), "utf8")]));
const { lines, exitCode } = checkComments(files);

for (const line of lines) console.log(line);

process.exitCode = exitCode;
