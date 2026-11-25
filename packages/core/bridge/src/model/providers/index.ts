// Every provider the bridge can use. Adding one is a new file and an entry
// here. docs/design/core/run-modes.md has the design.

import type { Logger } from "../../log.js";
import { anthropic } from "./anthropic.js";
import { google } from "./google.js";
import { openai } from "./openai.js";
import type { ProviderDef } from "./provider.js";

// The folder is the config file's, where a plan's tokens are saved.
export function providers(folder: string, log: Pick<Logger, "info" | "warn">): ProviderDef[] {
	return [anthropic, openai(folder, log), google];
}
