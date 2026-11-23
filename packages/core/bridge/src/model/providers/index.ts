// Every provider the bridge can use. Adding one is a new file and an entry
// here. docs/design/core/run-modes.md has the design.

import { anthropic } from "./anthropic.js";
import { google } from "./google.js";
import { openai } from "./openai.js";
import type { ProviderDef } from "./provider.js";

export const PROVIDERS: ProviderDef[] = [anthropic, openai, google];
