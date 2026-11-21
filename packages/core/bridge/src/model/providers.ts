// Builds a provider's model with the API key that startConfig filled in, from
// the config file or the environment. The key never comes from the game.
// docs/design/core/model-client.md has the design.

import { createAnthropic } from "@ai-sdk/anthropic";
import { createGoogle } from "@ai-sdk/google";
import { createOpenAI } from "@ai-sdk/openai";
import type { LanguageModel } from "ai";
import { type Config, KEY_VARIABLES, type Provider } from "../config.js";

const FACTORIES: Record<Provider, (apiKey: string) => (modelId: string) => LanguageModel> = {
	anthropic: (apiKey) => createAnthropic({ apiKey }),
	google: (apiKey) => createGoogle({ apiKey }),
	openai: (apiKey) => createOpenAI({ apiKey }),
};

export type ModelResult =
	| { ok: true; model: LanguageModel }
	| { ok: false; error: string };

// An empty key would let the SDK read an environment variable that
// withEnvironmentKeys doesn't read, so it fails here instead.
export function providerModel(config: Config, provider: Provider, modelId: string): ModelResult {
	const apiKey = config.providers[provider]?.apiKey ?? "";

	return apiKey === ""
		? { ok: false, error: `No API key for ${provider}. Set providers.${provider}.apiKey in the config file, or ${KEY_VARIABLES[provider]}` }
		: { ok: true, model: FACTORIES[provider](apiKey)(modelId) };
}
