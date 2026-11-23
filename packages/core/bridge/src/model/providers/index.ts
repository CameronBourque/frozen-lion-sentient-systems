// Every provider the bridge can use. Adding one is a new file and an entry
// here. docs/design/core/run-modes.md has the design.

import type { Config, Provider } from "../../config.js";
import type { ListResult } from "../list-models.js";
import { anthropic } from "./anthropic.js";
import { google } from "./google.js";
import { openai } from "./openai.js";
import type { ProviderDef } from "./provider.js";

export const PROVIDERS: ProviderDef[] = [anthropic, openai, google];

// The picker's model list, until the picker reads PROVIDERS itself.
export function listApiKeyModels(name: Provider, config: Config): Promise<ListResult> {
	const mode = PROVIDERS.find((provider) => provider.name === name)?.modes["api-key"];

	return mode === undefined ? Promise.resolve({ ok: false, error: `${name} has no API key mode` }) : mode.listModels(config);
}
