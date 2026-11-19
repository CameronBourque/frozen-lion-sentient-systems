// Checks that no Lua pattern in the mods uses a character class. Prints one
// line per problem as file:line: message, and exits 1 if there are any. The
// logic is in check.mjs.

import { execFileSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { checkPatterns } from "./check.mjs";

const root = path.resolve(import.meta.dirname, "../../..");

// The mods' Lua, without their tests, which run outside the game. Committed
// files plus new files that git doesn't ignore, as check-docs lists them.
const paths = execFileSync("git", ["ls-files", "-z", "--cached", "--others", "--exclude-standard", "packages/*/mod/*.lua"], { cwd: root, encoding: "utf8" })
	.split("\0")
	.filter((p) => p && !p.includes("/Test/") && fs.existsSync(path.join(root, p)));

const files = Object.fromEntries(paths.map((p) => [p, fs.readFileSync(path.join(root, p), "utf8")]));
const { lines, exitCode } = checkPatterns(files);

for (const line of lines) console.log(line);

process.exitCode = exitCode;
