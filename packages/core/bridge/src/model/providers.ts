// Builds a provider's model with the API key from the config file. The key
// never comes from the game or the environment.
// docs/design/core/model-client.md has the design.

import { createAnthropic } from "@ai-sdk/anthropic";
import { createGoogle } from "@ai-sdk/google";
import { createOpenAI } from "@ai-sdk/openai";
import type { LanguageModel } from "ai";
import type { Config, Provider } from "../config.js";

const FACTORIES: Record<Provider, (apiKey: string) => (modelId: string) => LanguageModel> = {
	anthropic: (apiKey) => createAnthropic({ apiKey }),
	google: (apiKey) => createGoogle({ apiKey }),
	openai: (apiKey) => createOpenAI({ apiKey }),
};

export type ModelResult =
	| { ok: true; model: LanguageModel }
	| { ok: false; error: string };

// An empty key would let the SDK fall back to an environment variable, so it
// fails here instead.
export function providerModel(config: Config, provider: Provider, modelId: string): ModelResult {
	const apiKey = config.providers[provider]?.apiKey ?? "";

	return apiKey === ""
		? { ok: false, error: `No API key for ${provider}. Set providers.${provider}.apiKey in the config file` }
		: { ok: true, model: FACTORIES[provider](apiKey)(modelId) };
}
