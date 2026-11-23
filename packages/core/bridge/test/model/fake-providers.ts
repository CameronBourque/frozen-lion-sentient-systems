// A config with only the given provider keys, for the provider tests.

import { type Config, DEFAULT_JOURNAL_ENTRIES, DEFAULT_MCP_PORT, NO_MODEL } from "../../src/config.js";

export function configWithKeys(providers: Config["providers"]): Config {
	return { schemaVersion: 1, logLevel: "decisions", providers, model: NO_MODEL, mcpPort: DEFAULT_MCP_PORT, journalEntries: DEFAULT_JOURNAL_ENTRIES };
}
