// Builds a run mode from where its credential comes from, how a model is made
// from it, and how its models are listed.
// docs/design/core/run-modes.md has the design.

import type { LanguageModel } from "ai";
import type { Config, Provider } from "../../config.js";
import { type Lister, listModels } from "../list-models.js";
import type { ModeSupport, Ready } from "./provider.js";

// Value is what a model is built from: an API key, or a plan's token source,
// which gets a fresh token on each request.
export interface Credential<Value> {
	ready: (config: Config) => Ready;
	value: (config: Config) => Value;
	// The string a request sends now, such as a key or the current token.
	current: (value: Value) => Promise<string>;
}

export type Factory<Value> = (value: Value) => (modelId: string) => LanguageModel;

export function credentialMode<Value>(name: Provider, credential: Credential<Value>, factory: Factory<Value>, lister: Lister): ModeSupport {
	return {
		ready: credential.ready,
		listModels: async (config, fetchPage) => listModels(name, lister, await credential.current(credential.value(config)), fetchPage),
		model: (config, modelId) => {
			const checked = credential.ready(config);

			return checked.ok ? { ok: true, model: factory(credential.value(config))(modelId) } : { ok: false, error: checked.reason };
		},
	};
}
