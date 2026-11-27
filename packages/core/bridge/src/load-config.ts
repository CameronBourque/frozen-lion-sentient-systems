// Finds and reads the config file, next to the executable or at --config. A
// missing file gets a commented template. docs/design/core/settings.md has
// the design.

import fs from "node:fs";
import path from "node:path";
import { parseArgs } from "node:util";
import { type Config, DEFAULT_JOURNAL_ENTRIES, DEFAULT_LIMITS, DEFAULT_MCP_PORT, EFFORTS, KEY_VARIABLES, type ModelSetting, NO_LIMIT, PROVIDER_NAMES, type Provider, SCHEMA_VERSION, parseConfig, withEnvironmentKeys, withModel } from "./config.js";
import { DEFAULT_LOG_LEVEL, LOG_LEVELS } from "./log.js";
import { RUN_MODE_NAMES } from "./model/providers/provider.js";

export const CONFIG_NAME = "sentient-systems.yaml";

// What the bridge writes when the file is missing. It must pass parseConfig,
// and a test checks it.
export const EXAMPLE_CONFIG = `# Settings for the Sentient Systems bridge. Agent slots, personalities, and sweat levels are
# chosen in the game's setup screen and saved with the game, so they aren't here.

# The version of this file's format. Leave it as it is. The bridge updates older files when it
# loads them.
schemaVersion: ${SCHEMA_VERSION}

# How much the bridge writes to its log, from quietest to noisiest: ${LOG_LEVELS.join(", ")}. Each
# level also writes every quieter level. "debug" also writes each prompt and response, so its logs
# can be large.
logLevel: ${DEFAULT_LOG_LEVEL}

# An API key for each provider whose models the agents use. Fill in at least one. Delete a provider
# you don't use. A blank key comes from its environment variable instead, if it is set:
# ${PROVIDER_NAMES.map((provider) => KEY_VARIABLES[provider]).join(", ")}.
providers:
${PROVIDER_NAMES.map((provider) => `  ${provider}:\n    apiKey: ""`).join("\n")}

# The model the agents use, and how hard it thinks before it answers. The bridge asks for these
# when it starts, and saves your choice here. The run mode is how the model is paid for, one of:
# ${RUN_MODE_NAMES.join(", ")}. The provider is one of: ${PROVIDER_NAMES.join(", ")}. The effort is
# one of: ${EFFORTS.join(", ")}.
model:
  mode: api-key
  provider: ""
  id: ""
  effort: ""
  # The model's price in US dollars per million tokens. The picker fills it from a public price
  # list, and you can change it. With a price, the log shows each call's cost. Picking another
  # model replaces it.
  price:
    input: ""
    output: ""
    cacheRead: ""
    cacheWrite: ""

# The port where the bridge serves its MCP tools when it starts with --mcp, for Claude Code and
# the MCP Inspector. Change it if another program uses it.
mcpPort: ${DEFAULT_MCP_PORT}

# How many of an agent's newest journal entries each turn's prompt holds. More entries give the
# agent more of its past, and cost more tokens on every turn.
journalEntries: ${DEFAULT_JOURNAL_ENTRIES}

# Limits on each agent turn, so one stuck turn can't stop a game. When the agent reaches one, the
# bridge logs a warning and ends its turn. retriesPerAction is how many actions in a row may fail,
# where a reply with no tool call counts as a failure. actionsPerTurn counts the tools that act in
# the game, not the ones that read it. turnMinutes is how long a turn may take.
#
# The spending limits cap the model calls, so an agent never spends more than you allow. Tokens
# count input and output. Cost is in US dollars, and needs the model's price. A turn that reaches
# its limit ends as it does at the limits above. A run, which is one start of the bridge, stops at
# its limit, and the game waits on the agent's turn until you start the bridge again. ${NO_LIMIT} is no
# limit. Write each limit as a plain number, with no quotes.
limits:
  retriesPerAction: ${DEFAULT_LIMITS.retriesPerAction}
  actionsPerTurn: ${DEFAULT_LIMITS.actionsPerTurn}
  turnMinutes: ${DEFAULT_LIMITS.turnMinutes}
  tokensPerTurn: ${NO_LIMIT}
  tokensPerRun: ${NO_LIMIT}
  costPerTurn: ${NO_LIMIT}
  costPerRun: ${NO_LIMIT}
`;

// Where the bridge runs from. In development, tsx runs the bridge with
// node.exe, so the folder of the executable would be Node's install folder.
export interface Runtime {
	args: string[];
	cwd: string;
	execPath: string;
	isExecutable: boolean;
	env: Record<string, string | undefined>;
}

// turns is how many agent turns the bridge plays before it stops, with no
// limit when it is undefined.
export type FindResult =
	| { ok: true; path: string; mcp: boolean; turns: number | undefined }
	| { ok: false; error: string };

const TURN_COUNT = /^[1-9]\d*$/;

// Returns the config file's path from --config, or the default for how the
// bridge runs: next to the executable, or in the current folder when tsx runs
// it. Also says whether --mcp is set, and the --turns count.
export function findConfigPath(runtime: Runtime): FindResult {
	let config: string | undefined;
	let mcp: boolean | undefined;
	let turns: string | undefined;

	try {
		({ values: { config, mcp, turns } } = parseArgs({ args: runtime.args, options: { config: { type: "string" }, mcp: { type: "boolean" }, turns: { type: "string" } } }));
	} catch (error) {
		// parseArgs throws for an unknown or incomplete option, such as a
		// misspelled "--confg".
		return { ok: false, error: (error as Error).message };
	}

	if (turns !== undefined && !TURN_COUNT.test(turns)) {
		return { ok: false, error: `--turns needs a whole number above 0, and got "${turns}"` };
	}

	const folder = runtime.isExecutable ? path.dirname(runtime.execPath) : runtime.cwd;
	const file = config === undefined ? path.join(folder, CONFIG_NAME) : path.resolve(runtime.cwd, config);

	return { ok: true, path: file, mcp: mcp ?? false, turns: turns === undefined ? undefined : Number(turns) };
}

export type LoadResult =
	| { result: "loaded"; config: Config }
	| { result: "created" }
	| { result: "invalid"; errors: string[] };

// Reads the config file at a path. A missing file gets the example, in a new
// folder if needed.
export function loadConfig(file: string): LoadResult {
	if (!fs.existsSync(file)) {
		fs.mkdirSync(path.dirname(file), { recursive: true });
		fs.writeFileSync(file, EXAMPLE_CONFIG);

		return { result: "created" };
	}

	const parsed = parseConfig(fs.readFileSync(file, "utf8"));

	return parsed.ok ? { result: "loaded", config: parsed.config } : { result: "invalid", errors: parsed.errors };
}

// Saves the picked model to the config file, or returns why it couldn't, such
// as a file that is read-only.
export function saveModel(file: string, model: ModelSetting): string | undefined {
	try {
		fs.writeFileSync(file, withModel(fs.readFileSync(file, "utf8"), model));

		return undefined;
	} catch (error) {
		return `Couldn't save the model to ${file}, so the bridge will ask again next time: ${(error as Error).message}`;
	}
}

// A warning when no provider has a key, since agents can't call a model without
// one.
export function keyWarning(config: Config, file: string): string | undefined {
	const hasKey = Object.values(config.providers).some((provider) => provider.apiKey !== "");

	return hasKey ? undefined : `No provider has an API key, so agents can't play yet. Add one in ${file}, or set ${Object.values(KEY_VARIABLES).join(", ")}`;
}

// What the bridge does with its config when it starts: run with the config and
// print the warnings, or print the error and exit.
export type StartResult =
	| { ok: true; config: Config; path: string; mcp: boolean; turns: number | undefined; warnings: string[]; environmentKeys: Provider[] }
	| { ok: false; error: string };

const OPTIONS = "The options are --config <path>, --mcp, and --turns <n>";

// Finds and loads the config file, and says what the user should do about each
// problem.
export function startConfig(runtime: Runtime): StartResult {
	const found = findConfigPath(runtime);

	if (!found.ok) {
		return { ok: false, error: `${found.error}. ${OPTIONS}` };
	}

	const loaded = loadConfig(found.path);

	if (loaded.result === "created") {
		return { ok: false, error: `There was no config file, so the bridge wrote an example at ${found.path}. Fill it in, then start the bridge again` };
	}

	if (loaded.result === "invalid") {
		return { ok: false, error: `The config file ${found.path} has errors:\n${loaded.errors.join("\n")}` };
	}

	const { config, providers } = withEnvironmentKeys(loaded.config, runtime.env);
	const warnings = [keyWarning(config, found.path), turnsWarning(found.mcp, found.turns)].filter((warning) => warning !== undefined);

	return { ok: true, config, path: found.path, mcp: found.mcp, turns: found.turns, warnings, environmentKeys: providers };
}

// With --mcp, the MCP client plays the turns, so no agent turn ends and the
// count is never reached.
function turnsWarning(mcp: boolean, turns: number | undefined): string | undefined {
	return mcp && turns !== undefined ? "--turns does nothing with --mcp, because the bridge plays no agent turns" : undefined;
}
