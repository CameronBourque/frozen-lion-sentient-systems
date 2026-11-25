// The API key run mode. The key comes from the config file, which
// withEnvironmentKeys fills from the environment when it is blank, never from
// the game. docs/design/core/run-modes.md has the design.

import { type Config, KEY_VARIABLES, type Provider } from "../../config.js";
import type { Lister } from "../list-models.js";
import { type Credential, type Factory, credentialMode } from "./mode.js";
import type { ModeSupport } from "./provider.js";

export function apiKeyCredential(name: Provider): Credential<string> {
	const keyOf = (config: Config) => config.providers[name]?.apiKey ?? "";

	return {
		// An empty key would let the SDK read an environment variable that
		// withEnvironmentKeys doesn't read, so it isn't ready.
		ready: (config) => keyOf(config) === ""
			? { ok: false, reason: `No API key for ${name}. Set providers.${name}.apiKey in the config file, or ${KEY_VARIABLES[name]}` }
			: { ok: true },
		source: keyOf,
		secret: (key) => Promise.resolve({ ok: true, secret: key }),
	};
}

export function apiKeyMode(name: Provider, factory: Factory<string>, lister: Lister): ModeSupport {
	return credentialMode(name, apiKeyCredential(name), factory, lister);
}
