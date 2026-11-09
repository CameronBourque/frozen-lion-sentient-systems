// Runs the core mod's Lua tests with luacov, prints the coverage summary, and
// exits 1 below the threshold. It needs busted and luacov, as
// docs/rules/testing.md says. The logic is in summary.mjs.

import { spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { checkCoverage } from "./summary.mjs";

const root = path.resolve(import.meta.dirname, "../../..");
// The folder that .luacov names for the stats and the report.
const folder = path.join(root, "coverage", "lua");

// luacov adds to the stats file from an earlier run, so each run starts with an
// empty folder.
fs.rmSync(folder, { recursive: true, force: true });
fs.mkdirSync(folder, { recursive: true });

// On Windows, LuaRocks installs busted and luacov as .bat files, which only a
// shell can run.
for (const command of ["busted --coverage", "luacov"]) {
	const { status } = spawnSync(command, { cwd: root, stdio: "inherit", shell: true });

	if (status !== 0) {
		console.error(`${command} exited with code ${status}.`);
		process.exit(1);
	}
}

const { summary, lines, exitCode } = checkCoverage(fs.readFileSync(path.join(folder, "luacov.report.out"), "utf8"));

// The CI job summary reads the table from this file.
if (summary !== null) fs.writeFileSync(path.join(folder, "summary.txt"), `${summary}\n`);

for (const line of lines) console.log(line);

process.exitCode = exitCode;
