// Builds a run mode from where its credential comes from, how a model is made
// from it, and how its models are listed.
// docs/design/core/run-modes.md has the design.

import type { LanguageModel } from "ai";
import { modelClientRunner } from "../../agents/runners/model-client-runner.js";
import type { Config, Provider } from "../../config.js";
import type { CallMode } from "../client.js";
import { type Lister, listModels } from "../list-models.js";
import type { CallModeSupport, ModelResult, Ready } from "./provider.js";

export type SecretResult =
	| { ok: true; secret: string }
	| { ok: false; error: string };

// Source is what a model is built from: an API key, or a plan's token store,
// which gets a fresh token on each request.
export interface Credential<Source> {
	ready: (config: Config) => Ready;
	source: (config: Config) => Source;
	// The string a request sends now, such as a key or a fresh token. A plan's
	// token can fail to refresh.
	secret: (source: Source) => Promise<SecretResult>;
}

export type Factory<Source> = (source: Source) => (modelId: string) => LanguageModel;

// The mode plays turns through the bridge's own loop, with the model.
export function credentialMode<Source>(name: Provider, mode: CallMode, credential: Credential<Source>, factory: Factory<Source>, lister: Lister): CallModeSupport {
	const model = (config: Config, modelId: string): ModelResult => {
		const checked = credential.ready(config);

		return checked.ok ? { ok: true, model: factory(credential.source(config))(modelId) } : { ok: false, error: checked.reason };
	};

	return {
		ready: credential.ready,
		listModels: async (config, fetchPage) => {
			const secret = await credential.secret(credential.source(config));

			return secret.ok ? listModels(name, lister, secret.secret, fetchPage) : { ok: false, error: secret.error };
		},
		model,
		runner: (config) => {
			const { id, effort } = config.model;
			const built = model(config, id);

			return built.ok ? { ok: true, runner: modelClientRunner({ model: built.model, provider: name, mode, effort }) } : built;
		},
	};
}
