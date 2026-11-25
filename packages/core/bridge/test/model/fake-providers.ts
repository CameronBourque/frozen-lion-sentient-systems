// A config with only the given provider keys, and the real providers with a
// fake model list, so a picker test keeps the real key check with no network.

import crypto from "node:crypto";
import os from "node:os";
import path from "node:path";
import { type Config, DEFAULT_JOURNAL_ENTRIES, DEFAULT_MCP_PORT, NO_MODEL, type Provider } from "../../src/config.js";
import type { ListResult } from "../../src/model/list-models.js";
import { providers } from "../../src/model/providers/index.js";
import type { ModeSupport, ProviderDef } from "../../src/model/providers/provider.js";

export function configWithKeys(providers: Config["providers"]): Config {
	return { schemaVersion: 1, logLevel: "decisions", providers, model: NO_MODEL, mcpPort: DEFAULT_MCP_PORT, journalEntries: DEFAULT_JOURNAL_ENTRIES };
}

// The real providers, signed out of every plan, since their folder has no
// saved tokens.
export function realProviders(): ProviderDef[] {
	return providers(path.join(os.tmpdir(), crypto.randomUUID()), { info: () => undefined, warn: () => undefined });
}

export function providersListing(list: (provider: Provider, config: Config) => Promise<ListResult>): ProviderDef[] {
	return realProviders().map(({ name, modes }) => ({
		name,
		modes: { "api-key": { ...modes["api-key"] as ModeSupport, listModels: (config) => list(name, config) } },
	}));
}
