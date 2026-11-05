// Checks the doc paths in the comments of the repo's yml files. Prints one line
// per problem as file:line: message, and exits 1 if there are any. The logic is
// in check.mjs.

import { execFileSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { repoDocs } from "../../comment-rules/src/doc-path-rule.mjs";
import { checkComments } from "./check.mjs";

const root = path.resolve(import.meta.dirname, "../../..");

// Committed files plus new files that git doesn't ignore, as check-docs lists
// them.
const paths = execFileSync("git", ["ls-files", "-z", "--cached", "--others", "--exclude-standard", "*.yml", "*.yaml"], { cwd: root, encoding: "utf8" })
	.split("\0")
	.filter((p) => p && fs.existsSync(path.join(root, p)));

const files = Object.fromEntries(paths.map((p) => [p, fs.readFileSync(path.join(root, p), "utf8")]));
const { lines, exitCode } = checkComments(files, repoDocs(root));

for (const line of lines) console.log(line);

process.exitCode = exitCode;
