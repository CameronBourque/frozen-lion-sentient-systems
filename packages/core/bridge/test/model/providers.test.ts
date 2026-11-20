// Tests for model/providers.ts: each provider builds its model from the key in
// the config, and an empty or missing key fails with the field to set.

import { describe, expect, test } from "vitest";
import { type Config, DEFAULT_MCP_PORT, PROVIDERS } from "../../src/config.js";
import { providerModel } from "../../src/model/providers.js";

function configWith(providers: Config["providers"]): Config {
	return { schemaVersion: 1, logLevel: "decisions", providers, mcpPort: DEFAULT_MCP_PORT };
}

describe.each(PROVIDERS)("%s", (provider) => {
	test("builds the model with the key from the config", () => {
		const result = providerModel(configWith({ [provider]: { apiKey: "key" } }), provider, "some-model");

		expect(result).toMatchObject({ ok: true, model: { modelId: "some-model" } });
	});

	test("fails with the field to set when the key is empty", () => {
		expect(providerModel(configWith({ [provider]: { apiKey: "" } }), provider, "some-model")).toEqual({
			ok: false,
			error: `No API key for ${provider}. Set providers.${provider}.apiKey in the config file`,
		});
	});

	test("fails when the provider isn't in the config", () => {
		expect(providerModel(configWith({}), provider, "some-model")).toMatchObject({ ok: false });
	});
});

test("names each provider's own model", () => {
	const config = configWith({ anthropic: { apiKey: "a" }, openai: { apiKey: "b" }, google: { apiKey: "c" } });
	const names = PROVIDERS.map((provider) => {
		const result = providerModel(config, provider, "m");

		return result.ok && typeof result.model === "object" ? result.model.provider : undefined;
	});

	expect(names).toEqual([expect.stringMatching(/^anthropic/), expect.stringMatching(/^openai/), expect.stringMatching(/^google/)]);
});
