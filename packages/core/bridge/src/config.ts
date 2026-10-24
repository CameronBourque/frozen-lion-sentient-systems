// The bridge's config file, sentient-systems.yaml. It holds settings for the whole bridge: the log
// level and each provider's API key. Agent slots, personalities, and sweat levels live in the save,
// not here. docs/design/core/settings.md has the design.

import { parseDocument } from "yaml";
import { z } from "zod";
import { DEFAULT_LOG_LEVEL, LOG_LEVELS } from "./log.js";

// Bump this when the format changes, and migrate older files when they load.
export const SCHEMA_VERSION = 1;

export const PROVIDERS = ["anthropic", "openai"] as const;

const PROVIDER = z.strictObject({
	// Empty until the user fills it in. The bridge warns about an empty key instead of exiting.
	apiKey: z.string().default(""),
});

// Strict objects, so a misspelled field, such as "loglevel", is an error and not a silent default.
const CONFIG = z.strictObject({
	schemaVersion: z.literal(SCHEMA_VERSION),
	logLevel: z.enum(LOG_LEVELS).default(DEFAULT_LOG_LEVEL),
	// Only the providers the user has a key for. A model from any listed provider can be used.
	providers: z.partialRecord(z.enum(PROVIDERS), PROVIDER).default({}),
});

export type Config = z.infer<typeof CONFIG>;

export type ConfigResult =
	| { ok: true; config: Config }
	| { ok: false; errors: string[] };

// Parses the file's text. Each error names the field it is about, such as
// "logLevel: Invalid option: expected one of "error"|"warn"|"info"|"decisions"|"debug"".
export function parseConfig(text: string): ConfigResult {
	const document = parseDocument(text);

	if (document.errors.length > 0) {
		return { ok: false, errors: document.errors.map((error) => `The file isn't valid YAML: ${error.message}`) };
	}

	const parsed = CONFIG.safeParse(document.toJS());

	return parsed.success
		? { ok: true, config: parsed.data }
		: { ok: false, errors: parsed.error.issues.flatMap(describeIssue) };
}

// The text for one schema issue, with the field's path in front.
function describeIssue(issue: z.core.$ZodIssue): string[] {
	const path = issue.path.join(".");

	// One issue lists every unknown field in an object, so give each field its own error.
	if (issue.code === "unrecognized_keys") {
		return issue.keys.map((key) => `${path === "" ? key : `${path}.${key}`}: Unknown field`);
	}

	return [`${path === "" ? "The file" : path}: ${issue.message}`];
}
