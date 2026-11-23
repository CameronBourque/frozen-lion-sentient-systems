// The API key run mode, which each provider builds from its AI SDK factory and
// its model list. The key comes from the config file or the environment, never
// from the game. docs/design/core/run-modes.md has the design.

import type { LanguageModel } from "ai";
import { type Config, KEY_VARIABLES, type Provider } from "../../config.js";
import { type Lister, listModels } from "../list-models.js";
import type { ModeSupport, Ready } from "./provider.js";

export type Factory = (apiKey: string) => (modelId: string) => LanguageModel;

export function apiKeyMode(name: Provider, factory: Factory, lister: Lister): ModeSupport {
	const keyOf = (config: Config) => config.providers[name]?.apiKey ?? "";

	// An empty key would let the SDK read an environment variable that
	// withEnvironmentKeys doesn't read, so it isn't ready.
	const ready = (config: Config): Ready => keyOf(config) === ""
		? { ok: false, reason: `No API key for ${name}. Set providers.${name}.apiKey in the config file, or ${KEY_VARIABLES[name]}` }
		: { ok: true };

	return {
		ready,
		listModels: (config, fetchPage) => listModels(name, lister, keyOf(config), fetchPage),
		model: (config, modelId) => {
			const checked = ready(config);

			return checked.ok ? { ok: true, model: factory(keyOf(config))(modelId) } : { ok: false, error: checked.reason };
		},
	};
}
