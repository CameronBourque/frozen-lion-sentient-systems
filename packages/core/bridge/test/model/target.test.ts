// Tests for model/target.ts, with the real providers and no network.

import { expect, test } from "vitest";
import type { Config } from "../../src/config.js";
import { agentRunner, modelTarget } from "../../src/model/target.js";
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

	expect(modelTarget(config, "agent-sdk", realProviders())).toEqual({ ok: false, error: "Agent SDK mode runs its own loop, which the model client can't call" });
});

test("fails when the provider has no such mode", () => {
	const config = withModel(configWithKeys({ anthropic: { apiKey: "sk-test" } }), "anthropic");

	expect(modelTarget(config, "subscription", realProviders())).toEqual({ ok: false, error: "anthropic has no Subscription token mode" });
});

test("passes on the reason a model can't be built", () => {
	const config = withModel(configWithKeys({}), "anthropic");

	expect(modelTarget(config, "api-key", realProviders())).toMatchObject({ ok: false, error: expect.stringContaining("apiKey") as unknown });
});

test("builds the runner for the chosen model's run mode", () => {
	const config = withModel(configWithKeys({ anthropic: { apiKey: "sk-test" } }), "anthropic");
	const built = agentRunner(config, "api-key", realProviders());

	expect(built.ok && typeof built.runner.runTurn).toBe("function");
});

test("builds no runner with no model chosen, or in a mode the provider doesn't have", () => {
	const config = withModel(configWithKeys({ anthropic: { apiKey: "sk-test" } }), "anthropic");

	expect(agentRunner(configWithKeys({}), "api-key", realProviders())).toEqual({ ok: false, error: "No model is chosen" });
	expect(agentRunner(config, "agent-sdk", realProviders())).toEqual({ ok: false, error: "anthropic has no Agent SDK mode" });
});

test("builds no runner when the mode can't build its model, and says why", () => {
	const config = withModel(configWithKeys({}), "anthropic");

	expect(agentRunner(config, "api-key", realProviders())).toMatchObject({ ok: false, error: expect.stringContaining("apiKey") as unknown });
});
