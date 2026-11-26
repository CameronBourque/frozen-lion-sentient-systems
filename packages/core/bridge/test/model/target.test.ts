// Tests for model/target.ts, with the real providers and no network.

import { expect, test } from "vitest";
import type { Config } from "../../src/config.js";
import { modelTarget } from "../../src/model/target.js";
import { configWithKeys, realProviders } from "./fake-providers.js";

function withModel(config: Config, provider: Config["model"]["provider"], id = "model-1"): Config {
	return { ...config, model: { ...config.model, provider, id, effort: "high" } };
}

test("builds the target for the chosen model in a mode the client calls", () => {
	const config = withModel(configWithKeys({ anthropic: { apiKey: "sk-test" } }), "anthropic");

	expect(modelTarget(config, "api-key", realProviders())).toMatchObject({ ok: true, target: { provider: "anthropic", mode: "api-key", effort: "high" } });
});

test("fails with no model chosen", () => {
	expect(modelTarget(configWithKeys({}), "api-key", realProviders())).toEqual({ ok: false, error: "No model is chosen" });
});

test("fails in a mode that runs its own loop", () => {
	const config = withModel(configWithKeys({ anthropic: { apiKey: "sk-test" } }), "anthropic");

	expect(modelTarget(config, "agent-sdk", realProviders())).toEqual({ ok: false, error: "Agent SDK mode runs its own loop, which the bridge can't call yet" });
});

test("fails when the provider has no such mode", () => {
	const config = withModel(configWithKeys({ anthropic: { apiKey: "sk-test" } }), "anthropic");

	expect(modelTarget(config, "subscription", realProviders())).toEqual({ ok: false, error: "anthropic has no Subscription token mode" });
});

test("passes on the reason a model can't be built", () => {
	const config = withModel(configWithKeys({}), "anthropic");

	expect(modelTarget(config, "api-key", realProviders())).toMatchObject({ ok: false, error: expect.stringContaining("apiKey") as unknown });
});
