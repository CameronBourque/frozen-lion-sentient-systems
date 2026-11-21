// The bridge's config file, sentient-systems.yaml: the log level, each
// provider's API key, and the MCP port. Agent slots and personalities live in
// the save. docs/design/core/settings.md has the design.

import type { generateText } from "ai";
import { parseDocument } from "yaml";
import { z } from "zod";
import { describeIssue } from "./errors.js";
import { DEFAULT_LOG_LEVEL, LOG_LEVELS } from "./log.js";

// Bump this when the format changes, and migrate older files when they load.
export const SCHEMA_VERSION = 1;

export const PROVIDERS = ["anthropic", "openai", "google"] as const;

export type Provider = typeof PROVIDERS[number];

// The first port after the two the game listens on, 4318 and 4319.
export const DEFAULT_MCP_PORT = 4320;

const PROVIDER = z.strictObject({
	// Empty until the user fills it in. The bridge warns about an empty key
	// instead of exiting.
	apiKey: z.string().default(""),
});

// The AI SDK's reasoning levels, which it has only as a type.
export type Effort = NonNullable<Parameters<typeof generateText>[0]["reasoning"]>;

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

// Blank until the user picks, which the picker then asks for.
const MODEL = z.strictObject({
	provider: z.union([z.literal(""), z.enum(PROVIDERS)]).default(""),
	id: z.string().default(""),
	effort: z.union([z.literal(""), z.enum(EFFORTS)]).default(""),
});

export type ModelSetting = z.infer<typeof MODEL>;

export const NO_MODEL: ModelSetting = { provider: "", id: "", effort: "" };

// Strict objects, so a misspelled field is an error and not a silent default.
const CONFIG = z.strictObject({
	schemaVersion: z.literal(SCHEMA_VERSION),
	logLevel: z.enum(LOG_LEVELS).default(DEFAULT_LOG_LEVEL),
	// Only the providers the user has a key for. A model from any listed
	// provider can be used.
	providers: z.partialRecord(z.enum(PROVIDERS), PROVIDER).default({}),
	model: MODEL.default(NO_MODEL),
	// Where --mcp serves the MCP tools.
	mcpPort: z.int().min(1).max(65535).default(DEFAULT_MCP_PORT),
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
