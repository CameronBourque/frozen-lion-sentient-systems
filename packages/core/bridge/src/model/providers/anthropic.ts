// Anthropic, in each run mode it supports.
// docs/design/core/run-modes.md has the design.

import { createAnthropic } from "@ai-sdk/anthropic";
import { z } from "zod";
import { type Lister, withParam } from "../list-models.js";
import { apiKeyMode } from "./api-key.js";
import type { ProviderDef } from "./provider.js";

const PAGE = z.object({
	data: z.array(z.object({ id: z.string(), display_name: z.string() })),
	has_more: z.boolean(),
	last_id: z.string().nullable(),
});

// Anthropic lists its models newest first.
const LISTER: Lister = {
	url: "https://api.anthropic.com/v1/models?limit=1000",
	headers: (apiKey) => ({ "x-api-key": apiKey, "anthropic-version": "2023-06-01" }),
	parse: (body, url) => {
		const page = PAGE.parse(body);

		return {
			models: page.data.map(({ id, display_name }) => ({ id, name: display_name })),
			next: page.has_more && page.last_id !== null ? withParam(url, "after_id", page.last_id) : undefined,
		};
	},
};

export const anthropic: ProviderDef = {
	name: "anthropic",
	modes: {
		"api-key": apiKeyMode("anthropic", (apiKey) => createAnthropic({ apiKey }), LISTER),
	},
};
