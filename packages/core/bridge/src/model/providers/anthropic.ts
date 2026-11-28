// Anthropic, in each run mode it supports.
// docs/design/core/run-modes.md has the design.

import { createAnthropic } from "@ai-sdk/anthropic";
import { z } from "zod";
import { type Lister, withParam } from "../list-models.js";
import { type AgentSdk, agentSdkMode } from "./anthropic-agent-sdk.js";
import { apiKeyMode } from "./api-key.js";
import type { ProviderDef } from "./provider.js";

const API_KEY_PAGE = z.object({
	data: z.array(z.object({ id: z.string(), display_name: z.string() })),
	has_more: z.boolean(),
	last_id: z.string().nullable(),
});

// Anthropic lists its models newest first.
const API_KEY_LISTER: Lister = {
	url: "https://api.anthropic.com/v1/models?limit=1000",
	headers: (key) => ({ "x-api-key": key, "anthropic-version": "2023-06-01" }),
	parse: (body, url) => {
		const page = API_KEY_PAGE.parse(body);

		return {
			models: page.data.map(({ id, display_name }) => ({ id, name: display_name })),
			next: page.has_more && page.last_id !== null ? withParam(url, "after_id", page.last_id) : undefined,
		};
	},
};

// Off until Anthropic approves claude.ai login for the bridge. A setting would
// let anyone turn it on, so it is a constant, and tests pass enabled.
export const CLAUDE_AGENT_SDK_ENABLED = false;

export function anthropic(enabled = CLAUDE_AGENT_SDK_ENABLED, sdk?: AgentSdk): ProviderDef {
	return {
		name: "anthropic",
		modes: {
			"api-key": apiKeyMode("anthropic", (apiKey) => createAnthropic({ apiKey }), API_KEY_LISTER),
			...(enabled ? { "agent-sdk": agentSdkMode(sdk) } : {}),
		},
	};
}
