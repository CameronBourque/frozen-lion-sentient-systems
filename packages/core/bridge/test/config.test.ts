// Tests for config.ts.

import { describe, expect, test } from "vitest";
import { DEFAULT_MCP_PORT, parseConfig } from "../src/config.js";

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
			"mcpPort: 5000",
		].join("\n");

		expect(parseConfig(text)).toEqual({
			ok: true,
			config: {
				schemaVersion: 1,
				logLevel: "debug",
				providers: { anthropic: { apiKey: "key-a" }, openai: { apiKey: "key-b" } },
				mcpPort: 5000,
			},
		});
	});

	test("fills in the defaults for a file with only the schema version", () => {
		expect(parseConfig("schemaVersion: 1")).toEqual({
			ok: true,
			config: { schemaVersion: 1, logLevel: "decisions", providers: {}, mcpPort: DEFAULT_MCP_PORT },
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
