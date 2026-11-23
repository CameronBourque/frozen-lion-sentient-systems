// A config with only the given provider keys, and the real providers with a
// fake model list, so a picker test keeps the real key check with no network.

import { type Config, DEFAULT_JOURNAL_ENTRIES, DEFAULT_MCP_PORT, NO_MODEL, type Provider } from "../../src/config.js";
import type { ListResult } from "../../src/model/list-models.js";
import { PROVIDERS } from "../../src/model/providers/index.js";
import type { ModeSupport, ProviderDef } from "../../src/model/providers/provider.js";

export function configWithKeys(providers: Config["providers"]): Config {
	return { schemaVersion: 1, logLevel: "decisions", providers, model: NO_MODEL, mcpPort: DEFAULT_MCP_PORT, journalEntries: DEFAULT_JOURNAL_ENTRIES };
}

export function providersListing(list: (provider: Provider, config: Config) => Promise<ListResult>): ProviderDef[] {
	return PROVIDERS.map(({ name, modes }) => ({
		name,
		modes: { "api-key": { ...modes["api-key"] as ModeSupport, listModels: (config) => list(name, config) } },
	}));
}
