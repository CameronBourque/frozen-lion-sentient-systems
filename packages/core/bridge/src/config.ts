// The bridge's config file, sentient-systems.yaml: the log level, each
// provider's API key, and the MCP port. Agent slots and personalities live in
// the save. docs/design/core/settings.md has the design.

import type { streamText } from "ai";
import { parseDocument } from "yaml";
import { z } from "zod";
import { describeIssue } from "./errors.js";
import { DEFAULT_LOG_LEVEL, LOG_LEVELS } from "./log.js";
import { RUN_MODE_NAMES } from "./model/providers/provider.js";

// Bump this when the format changes, and migrate older files when they load.
export const SCHEMA_VERSION = 1;

export const PROVIDER_NAMES = ["anthropic", "openai", "google", "xai"] as const;

export type Provider = typeof PROVIDER_NAMES[number];

// Where a provider's key comes from when the config file leaves it blank.
export const KEY_VARIABLES: Record<Provider, string> = {
	anthropic: "ANTHROPIC_API_KEY",
	openai: "OPENAI_API_KEY",
	google: "GOOGLE_API_KEY",
	xai: "XAI_API_KEY",
};

// The first port after the two the game listens on, 4318 and 4319.
export const DEFAULT_MCP_PORT = 4320;

export const DEFAULT_JOURNAL_ENTRIES = 10;

const PROVIDER = z.strictObject({
	// Empty until the user fills it in. The bridge warns about an empty key
	// instead of exiting.
	apiKey: z.string().default(""),
});

// The AI SDK's reasoning levels, which it has only as a type.
export type Effort = NonNullable<Parameters<typeof streamText>[0]["reasoning"]>;

// A record needs every level and allows no others, so the type check fails
// when the SDK adds or drops one. The order is the picker's.
const EFFORT_LEVELS: Record<Effort, true> = {
	"provider-default": true,
	none: true,
	minimal: true,
	low: true,
	medium: true,
	high: true,
	xhigh: true,
	max: true,
};

export const EFFORTS = Object.keys(EFFORT_LEVELS) as Effort[];

// US dollars per million tokens, blank when the user doesn't know it. No API
// gives a price, so the user copies it from the provider's pricing page.
const PER_MILLION = z.union([z.literal(""), z.number().nonnegative()]).default("");

// Cached input is read from, or written to, the provider's prompt cache,
// which has its own prices.
const PRICE = z.strictObject({
	input: PER_MILLION,
	output: PER_MILLION,
	cacheRead: PER_MILLION,
	cacheWrite: PER_MILLION,
});

export type Price = z.infer<typeof PRICE>;

export const NO_PRICE: Price = { input: "", output: "", cacheRead: "", cacheWrite: "" };

// Blank until the user picks, which the picker then asks for. The run mode is
// the one the model was picked in, so keeping the model keeps how it pays.
const MODEL = z.strictObject({
	mode: z.enum(RUN_MODE_NAMES).default("api-key"),
	provider: z.union([z.literal(""), z.enum(PROVIDER_NAMES)]).default(""),
	id: z.string().default(""),
	effort: z.union([z.literal(""), z.enum(EFFORTS)]).default(""),
	price: PRICE.default(NO_PRICE),
});

export type ModelSetting = z.infer<typeof MODEL>;

export const NO_MODEL: ModelSetting = { mode: "api-key", provider: "", id: "", effort: "", price: NO_PRICE };

// Strict objects, so a misspelled field is an error and not a silent default.
const CONFIG = z.strictObject({
	schemaVersion: z.literal(SCHEMA_VERSION),
	logLevel: z.enum(LOG_LEVELS).default(DEFAULT_LOG_LEVEL),
	// Only the providers the user has a key for. A model from any listed
	// provider can be used.
	providers: z.partialRecord(z.enum(PROVIDER_NAMES), PROVIDER).default({}),
	model: MODEL.default(NO_MODEL),
	// Where --mcp serves the MCP tools.
	mcpPort: z.int().min(1).max(65535).default(DEFAULT_MCP_PORT),
	// How many of the newest journal entries each turn's prompt holds.
	journalEntries: z.int().min(0).default(DEFAULT_JOURNAL_ENTRIES),
});

export type Config = z.infer<typeof CONFIG>;

export type ConfigResult =
	| { ok: true; config: Config }
	| { ok: false; errors: string[] };

// Parses the file's text. Each error names the field it is about.
export function parseConfig(text: string): ConfigResult {
	const document = parseDocument(text);

	if (document.errors.length > 0) {
		return { ok: false, errors: document.errors.map((error) => `The file isn't valid YAML: ${error.message}`) };
	}

	const parsed = CONFIG.safeParse(document.toJS());

	return parsed.success
		? { ok: true, config: parsed.data }
		: { ok: false, errors: parsed.error.issues.flatMap((issue) => describeIssue(issue, "The file")) };
}

// Returns the file's text with a new model, keeping its comments and the rest
// of its fields. Each price is set on its own, so the comments inside price
// stay too.
export function withModel(text: string, model: ModelSetting): string {
	const document = parseDocument(text);
	const { price, ...rest } = model;

	for (const [field, value] of Object.entries(rest)) {
		document.setIn(["model", field], value);
	}

	for (const [field, value] of Object.entries(price)) {
		document.setIn(["model", "price", field], value);
	}

	return document.toString();
}

export interface EnvironmentKeys {
	config: Config;
	// The providers whose key came from the environment.
	providers: Provider[];
}

function environmentKey(env: Record<string, string | undefined>, provider: Provider): string {
	return env[KEY_VARIABLES[provider]]?.trim() ?? "";
}

// Fills each blank key from its environment variable. A key in the file wins,
// and the file itself never gets the environment's key.
export function withEnvironmentKeys(config: Config, env: Record<string, string | undefined>): EnvironmentKeys {
	const fromEnvironment = PROVIDER_NAMES.filter((provider) =>
		(config.providers[provider]?.apiKey ?? "") === "" && environmentKey(env, provider) !== "");
	const filled = Object.fromEntries(fromEnvironment.map((provider) => [provider, { apiKey: environmentKey(env, provider) }]));

	return { config: { ...config, providers: { ...config.providers, ...filled } }, providers: fromEnvironment };
}
