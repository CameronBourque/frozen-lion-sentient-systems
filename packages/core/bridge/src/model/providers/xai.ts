// xAI, in each run mode it supports. Its plan sign-in waits on xAI, so it is
// API key only. docs/design/core/run-modes.md has the design.

import { createXai } from "@ai-sdk/xai";
import { z } from "zod";
import type { Lister } from "../list-models.js";
import { apiKeyMode } from "./api-key.js";
import type { ProviderDef } from "./provider.js";

const API_KEY_PAGE = z.object({
	models: z.array(z.object({ id: z.string(), created: z.number() })),
});

// The language models list leaves out the image and video generators, which
// /v1/models includes. It comes in one page.
const API_KEY_LISTER: Lister = {
	url: "https://api.x.ai/v1/language-models",
	headers: (key) => ({ Authorization: `Bearer ${key}` }),
	parse: (body) => ({
		models: API_KEY_PAGE.parse(body).models
			.sort((a, b) => b.created - a.created)
			.map(({ id }) => ({ id, name: id })),
	}),
};

export const xai: ProviderDef = {
	name: "xai",
	modes: {
		"api-key": apiKeyMode("xai", (apiKey) => createXai({ apiKey }), API_KEY_LISTER),
	},
};
