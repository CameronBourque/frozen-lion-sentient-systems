// Links the core mod into the game's user mods folder, so the game loads this checkout.
// Usage: npm run link-mod, or npm run link-mod -- --remove to remove the link.
// This file only reads the registry and prints. documents.mjs and link.mjs hold the logic, so tests can reach it.

import { execFileSync } from "node:child_process";
import os from "node:os";
import path from "node:path";
import { parseArgs } from "node:util";
import { findDocuments, REGISTRY_KEY, REGISTRY_VALUE } from "./documents.mjs";
import { linkMod, unlinkMod } from "./link.mjs";

// Junctions and the registry are Windows only.
if (process.platform !== "win32") {
	console.error("link-mod runs on Windows only.");
	process.exit(1);
}

let remove;

try {
	remove = parseArgs({ options: { remove: { type: "boolean", default: false } } }).values.remove;
} catch (error) {
	console.error(`${error.message}\nUsage: npm run link-mod [-- --remove]`);
	process.exit(1);
}

const target = path.resolve(import.meta.dirname, "../../../packages/core/mod");

const { documents, warnings } = findDocuments({
	readRegistry: () => execFileSync("reg", ["query", REGISTRY_KEY, "/v", REGISTRY_VALUE], { encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] }),
	env: process.env,
	homedir: os.homedir(),
});

for (const warning of warnings) console.warn(`Warning: ${warning}`);

const { lines, exitCode } = remove ? unlinkMod({ documents }) : linkMod({ documents, target });

for (const line of lines) console.log(line);

process.exitCode = exitCode;
