// Tests for model/providers/api-key.ts: each provider is ready and builds its
// model with the key from the config, and an empty or missing key fails with
// the field to set.

import { describe, expect, test } from "vitest";
import { KEY_VARIABLES } from "../../../src/config.js";
import { PROVIDERS } from "../../../src/model/providers/index.js";
import type { ModeSupport } from "../../../src/model/providers/provider.js";
import { configWithKeys } from "../fake-providers.js";

describe.each(PROVIDERS)("$name", ({ name, modes }) => {
	const mode = modes["api-key"] as ModeSupport;
	const missing = `No API key for ${name}. Set providers.${name}.apiKey in the config file, or ${KEY_VARIABLES[name]}`;

	test("is ready and builds the model with the key from the config", () => {
		const config = configWithKeys({ [name]: { apiKey: "key" } });

		expect(mode.ready(config)).toEqual({ ok: true });
		expect(mode.model(config, "some-model")).toMatchObject({ ok: true, model: { modelId: "some-model" } });
	});

	test("isn't ready, and fails with the field to set, when the key is empty", () => {
		const config = configWithKeys({ [name]: { apiKey: "" } });

		expect(mode.ready(config)).toEqual({ ok: false, reason: missing });
		expect(mode.model(config, "some-model")).toEqual({ ok: false, error: missing });
	});

	test("isn't ready when the provider isn't in the config", () => {
		expect(mode.ready(configWithKeys({}))).toEqual({ ok: false, reason: missing });
	});
});

test("names each provider's own model", () => {
	const config = configWithKeys({ anthropic: { apiKey: "a" }, openai: { apiKey: "b" }, google: { apiKey: "c" } });
	const names = PROVIDERS.map(({ modes }) => {
		const result = (modes["api-key"] as ModeSupport).model(config, "m");

		return result.ok && typeof result.model === "object" ? result.model.provider : undefined;
	});

	expect(names).toEqual([expect.stringMatching(/^anthropic/), expect.stringMatching(/^openai/), expect.stringMatching(/^google/)]);
});
