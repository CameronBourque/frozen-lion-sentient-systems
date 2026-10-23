// Finds and reads the config file. The bridge looks for sentient-systems.yaml next to its
// executable, or reads the path in --config. A missing file gets a commented example, so the user
// has something to fill in. docs/design/core/bridge.md has the design.

import fs from "node:fs";
import path from "node:path";
import { parseArgs } from "node:util";
import { type Config, LOG_LEVELS, PROVIDERS, SCHEMA_VERSION, parseConfig } from "./config.js";

export const CONFIG_NAME = "sentient-systems.yaml";

// What the bridge writes when the file is missing. It must pass parseConfig, and a test checks it.
export const EXAMPLE_CONFIG = `# Settings for the Sentient Systems bridge. Agent slots, personalities, and sweat levels are
# chosen in the game's setup screen and saved with the game, so they aren't here.

# The version of this file's format. Leave it as it is. The bridge updates older files when it
# loads them.
schemaVersion: ${SCHEMA_VERSION}

# How much the bridge writes to its log: ${LOG_LEVELS.join(", ")}. Warnings and errors are written at
# every level. "full" also writes each prompt and response, so its logs can be large.
logLevel: decisions

# An API key for each provider whose models the agents use. Fill in at least one. Delete a provider
# you don't use.
providers:
${PROVIDERS.map((provider) => `  ${provider}:\n    apiKey: ""`).join("\n")}
`;

// Where the bridge runs from. In development, tsx runs the bridge with node.exe, so the folder of
// the executable would be Node's install folder.
export interface Runtime {
	args: string[];
	cwd: string;
	execPath: string;
	isExecutable: boolean;
}

export type FindResult =
	| { ok: true; path: string }
	| { ok: false; error: string };

// Returns the config file's path from --config, or the default for how the bridge runs: next to
// the executable, or in the current folder when tsx runs it.
export function findConfigPath(runtime: Runtime): FindResult {
	let config: string | undefined;

	try {
		({ values: { config } } = parseArgs({ args: runtime.args, options: { config: { type: "string" } } }));
	} catch (error) {
		// parseArgs throws for an unknown or incomplete option, such as a misspelled "--confg".
		return { ok: false, error: (error as Error).message };
	}

	if (config !== undefined) {
		return { ok: true, path: path.resolve(runtime.cwd, config) };
	}

	const folder = runtime.isExecutable ? path.dirname(runtime.execPath) : runtime.cwd;

	return { ok: true, path: path.join(folder, CONFIG_NAME) };
}

export type LoadResult =
	| { result: "loaded"; config: Config }
	| { result: "created" }
	| { result: "invalid"; errors: string[] };

// Reads the config file at a path. A missing file gets the example, in a new folder if needed.
export function loadConfig(file: string): LoadResult {
	if (!fs.existsSync(file)) {
		fs.mkdirSync(path.dirname(file), { recursive: true });
		fs.writeFileSync(file, EXAMPLE_CONFIG);

		return { result: "created" };
	}

	const parsed = parseConfig(fs.readFileSync(file, "utf8"));

	return parsed.ok ? { result: "loaded", config: parsed.config } : { result: "invalid", errors: parsed.errors };
}

// A warning when no provider has a key, since agents can't call a model without one.
export function keyWarning(config: Config, file: string): string | undefined {
	const hasKey = Object.values(config.providers).some((provider) => provider.apiKey !== "");

	return hasKey ? undefined : `No provider has an API key, so agents can't play yet. Add one in ${file}`;
}

// What the bridge does with its config when it starts: run with the config and print the
// warnings, or print the error and exit.
export type StartResult =
	| { ok: true; config: Config; path: string; warnings: string[] }
	| { ok: false; error: string };

// Finds and loads the config file, and says what the user should do about each problem.
export function startConfig(runtime: Runtime): StartResult {
	const found = findConfigPath(runtime);

	if (!found.ok) {
		return { ok: false, error: `${found.error}. The only option is --config <path>` };
	}

	const loaded = loadConfig(found.path);

	if (loaded.result === "created") {
		return { ok: false, error: `There was no config file, so the bridge wrote an example at ${found.path}. Fill it in, then start the bridge again` };
	}

	if (loaded.result === "invalid") {
		return { ok: false, error: `The config file ${found.path} has errors:\n${loaded.errors.join("\n")}` };
	}

	const missingKey = keyWarning(loaded.config, found.path);

	return { ok: true, config: loaded.config, path: found.path, warnings: missingKey ? [missingKey] : [] };
}
