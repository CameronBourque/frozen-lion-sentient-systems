// Tests for config.ts.

import { describe, expect, test } from "vitest";
import { DEFAULT_MCP_PORT, NO_MODEL, parseConfig, withEnvironmentKeys, withModel } from "../src/config.js";

// Returns the errors for a file the test expects to fail.
function errorsFor(text: string): string[] {
	const result = parseConfig(text);

	if (result.ok) {
		throw new Error("Expected the config to fail");
	}

	return result.errors;
}

describe("parseConfig", () => {
	test("reads a full file", () => {
		const text = [
			"schemaVersion: 1",
			"logLevel: debug",
			"providers:",
			"  anthropic:",
			"    apiKey: key-a",
			"  openai:",
			"    apiKey: key-b",
			"model:",
			"  provider: openai",
			"  id: some-model",
			"  effort: high",
			"mcpPort: 5000",
		].join("\n");

		expect(parseConfig(text)).toEqual({
			ok: true,
			config: {
				schemaVersion: 1,
				logLevel: "debug",
				providers: { anthropic: { apiKey: "key-a" }, openai: { apiKey: "key-b" } },
				model: { provider: "openai", id: "some-model", effort: "high" },
				mcpPort: 5000,
			},
		});
	});

	test("fills in the defaults for a file with only the schema version", () => {
		expect(parseConfig("schemaVersion: 1")).toEqual({
			ok: true,
			config: { schemaVersion: 1, logLevel: "decisions", providers: {}, model: NO_MODEL, mcpPort: DEFAULT_MCP_PORT },
		});
	});

	test("gives a provider with no key an empty key", () => {
		expect(parseConfig("schemaVersion: 1\nproviders:\n  anthropic: {}")).toMatchObject({
			ok: true,
			config: { providers: { anthropic: { apiKey: "" } } },
		});
	});

	test("names logLevel when its value is wrong", () => {
		const errors = errorsFor("schemaVersion: 1\nlogLevel: loud");

		expect(errors).toHaveLength(1);
		expect(errors[0]).toMatch(/^logLevel: /);
	});

	test("names schemaVersion when it is missing", () => {
		expect(errorsFor("logLevel: debug")[0]).toMatch(/^schemaVersion: /);
	});

	test("names schemaVersion when it is from another version", () => {
		expect(errorsFor("schemaVersion: 2")[0]).toMatch(/^schemaVersion: /);
	});

	test("fills in a blank model for a partial model", () => {
		expect(parseConfig("schemaVersion: 1\nmodel:\n  id: some-model")).toMatchObject({
			ok: true,
			config: { model: { provider: "", id: "some-model", effort: "" } },
		});
	});

	test("names the model field when its value is wrong", () => {
		expect(errorsFor("schemaVersion: 1\nmodel:\n  provider: acme")[0]).toMatch(/^model\.provider: /);
		expect(errorsFor("schemaVersion: 1\nmodel:\n  effort: huge")[0]).toMatch(/^model\.effort: /);
	});

	test("names mcpPort when it isn't a port", () => {
		expect(errorsFor("schemaVersion: 1\nmcpPort: 70000")[0]).toMatch(/^mcpPort: /);
		expect(errorsFor("schemaVersion: 1\nmcpPort: 43.5")[0]).toMatch(/^mcpPort: /);
	});

	test("names the full path of a provider's bad key", () => {
		expect(errorsFor("schemaVersion: 1\nproviders:\n  openai:\n    apiKey: 5")[0]).toMatch(/^providers\.openai\.apiKey: /);
	});

	test("names an unknown provider", () => {
		expect(errorsFor("schemaVersion: 1\nproviders:\n  acme:\n    apiKey: x")[0]).toMatch(/^providers/);
	});

	test("names each misspelled field", () => {
		expect(errorsFor("schemaVersion: 1\nloglevel: debug\nprovider: x")).toEqual([
			"loglevel: Unknown field",
			"provider: Unknown field",
		]);
	});

	test("names a misspelled field inside a provider", () => {
		expect(errorsFor("schemaVersion: 1\nproviders:\n  anthropic:\n    apikey: x")).toEqual([
			"providers.anthropic.apikey: Unknown field",
		]);
	});

	test("says an empty file isn't a config", () => {
		expect(errorsFor("")[0]).toMatch(/^The file: /);
	});

	test("says text that isn't YAML isn't valid", () => {
		expect(errorsFor("schemaVersion: [1")[0]).toMatch(/^The file isn't valid YAML: /);
	});
});

describe("withModel", () => {
	const MODEL = { provider: "openai", id: "some-model", effort: "high" } as const;

	// Each value keeps the quotes it had.
	test("replaces the model and keeps the comments", () => {
		const text = "# The model.\nmodel:\n  # Picked by the bridge.\n  provider: \"\"\n  id: \"\"\n  effort: \"\"\n";

		expect(withModel(text, MODEL)).toBe("# The model.\nmodel:\n  # Picked by the bridge.\n  provider: \"openai\"\n  id: \"some-model\"\n  effort: \"high\"\n");
	});

	test("adds the model to a file without one", () => {
		const text = withModel("schemaVersion: 1\n", MODEL);

		expect(parseConfig(text)).toMatchObject({ ok: true, config: { schemaVersion: 1, model: MODEL } });
	});
});

describe("withEnvironmentKeys", () => {
	const BASE = { schemaVersion: 1, logLevel: "decisions", model: NO_MODEL, mcpPort: DEFAULT_MCP_PORT } as const;

	test("fills a blank or missing key from its variable", () => {
		const config = { ...BASE, providers: { anthropic: { apiKey: "" } } };

		expect(withEnvironmentKeys(config, { ANTHROPIC_API_KEY: "env-a", GOOGLE_API_KEY: " env-g\n" })).toEqual({
			config: { ...BASE, providers: { anthropic: { apiKey: "env-a" }, google: { apiKey: "env-g" } } },
			providers: ["anthropic", "google"],
		});
	});

	test("keeps a key from the file over the variable", () => {
		const config = { ...BASE, providers: { openai: { apiKey: "file-key" } } };

		expect(withEnvironmentKeys(config, { OPENAI_API_KEY: "env-key" })).toEqual({ config, providers: [] });
	});

	test("ignores a variable that is blank", () => {
		const config = { ...BASE, providers: {} };

		expect(withEnvironmentKeys(config, { OPENAI_API_KEY: "  " })).toEqual({ config, providers: [] });
	});
});
