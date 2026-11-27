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

// A number setting with this value is unset: no price, or no limit. A number,
// not a blank string, so a user who quotes a number gets an error.
export const UNSET = -1;

// Every bad value gets the same error, which says how to write a good one.
function numberOrUnset(unset: string, valid: (value: number) => boolean, what: string): z.ZodNumber {
	const error = `Write ${UNSET} for ${unset}, or ${what}, with no quotes`;

	return z.number({ error }).refine((value) => value === UNSET || valid(value), { error });
}

// US dollars per million tokens, unset when the user doesn't know it. No API
// gives a price, so the user copies it from the provider's pricing page. A
// blank string was the unset price before, and older files still hold it.
const PER_MILLION = z.preprocess(
	(value) => (value === "" ? UNSET : value),
	numberOrUnset("no price", (value) => Number.isFinite(value) && value >= 0, "a dollar amount of 0 or more"),
).default(UNSET);

// Cached input is read from, or written to, the provider's prompt cache,
// which has its own prices.
const PRICE = z.strictObject({
	input: PER_MILLION,
	output: PER_MILLION,
	cacheRead: PER_MILLION,
	cacheWrite: PER_MILLION,
});

export type Price = z.infer<typeof PRICE>;

export const NO_PRICE: Price = { input: UNSET, output: UNSET, cacheRead: UNSET, cacheWrite: UNSET };

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

// A late-game turn moves many units and runs many cities, so the actions per
// turn leave room for it. There is no spending limit until the user sets one.
export const DEFAULT_LIMITS = {
	retriesPerAction: 3,
	actionsPerTurn: 250,
	turnMinutes: 15,
	tokensPerTurn: UNSET,
	tokensPerRun: UNSET,
	costPerTurn: UNSET,
	costPerRun: UNSET,
};

const TOKEN_LIMIT = numberOrUnset("no limit", (value) => Number.isInteger(value) && value > 0, "a whole number above 0").default(UNSET);

// In US dollars, which needs the model's price.
const COST_LIMIT = numberOrUnset("no limit", (value) => Number.isFinite(value) && value > 0, "a dollar amount above 0").default(UNSET);

// When the loop reaches a turn limit, it ends the turn, so one stuck turn can't
// stop a game. A run limit stops the bridge.
const LIMITS = z.strictObject({
	retriesPerAction: z.int().min(0).default(DEFAULT_LIMITS.retriesPerAction),
	actionsPerTurn: z.int().min(1).default(DEFAULT_LIMITS.actionsPerTurn),
	turnMinutes: z.number().positive().default(DEFAULT_LIMITS.turnMinutes),
	tokensPerTurn: TOKEN_LIMIT,
	tokensPerRun: TOKEN_LIMIT,
	costPerTurn: COST_LIMIT,
	costPerRun: COST_LIMIT,
});

export type Limits = z.infer<typeof LIMITS>;

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
	limits: LIMITS.default(DEFAULT_LIMITS),
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
