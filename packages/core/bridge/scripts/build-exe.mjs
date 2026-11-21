// Builds the bridge into one executable in dist/, for the release workflow to
// upload. esbuild bundles src/main.ts into build/main.cjs, and Node SEA turns
// that file and the knowledge files into the executable.

import { execFileSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { build } from "esbuild";

const bridge = path.resolve(import.meta.dirname, "..");

// The release uploads every file in dist/, so start it empty. --build-sea won't
// create it.
fs.rmSync(path.join(bridge, "dist"), { recursive: true, force: true });
fs.mkdirSync(path.join(bridge, "dist"));

await build({
	absWorkingDir: bridge,
	entryPoints: ["src/main.ts"],
	bundle: true,
	platform: "node",
	format: "cjs",
	outfile: "build/main.cjs",
});

// Each asset's key is its path from the bridge folder with forward slashes,
// which src/knowledge.ts reads.
const knowledge = fs.readdirSync(path.join(bridge, "knowledge"), { recursive: true, withFileTypes: true })
	.filter((entry) => entry.isFile())
	.map((entry) => path.relative(bridge, path.join(entry.parentPath, entry.name)).split(path.sep).join("/"));
const config = JSON.parse(fs.readFileSync(path.join(bridge, "sea-config.json"), "utf8"));

config.assets = Object.fromEntries(knowledge.map((file) => [file, file]));
fs.writeFileSync(path.join(bridge, "build", "sea-config.json"), JSON.stringify(config, null, "\t"));

execFileSync(process.execPath, ["--build-sea", "build/sea-config.json"], { cwd: bridge, stdio: "inherit" });
