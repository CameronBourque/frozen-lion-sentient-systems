// Builds the bridge into one executable in dist/, for the release workflow to upload.
// Usage: npm run build:exe --workspace packages/core/bridge
// esbuild bundles src/main.ts and its dependencies into build/main.cjs, and Node SEA
// turns that file into the executable that sea-config.json names.

import { execFileSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { build } from "esbuild";

const bridge = path.resolve(import.meta.dirname, "..");

// The release uploads every file in dist/, so start it empty. --build-sea won't create it.
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

execFileSync(process.execPath, ["--build-sea", "sea-config.json"], { cwd: bridge, stdio: "inherit" });
