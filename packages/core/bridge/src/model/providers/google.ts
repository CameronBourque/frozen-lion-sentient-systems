// Google, in each run mode it supports. It has no plan mode, so it is API key
// only. docs/design/core/run-modes.md has the design.

import { createGoogle } from "@ai-sdk/google";
import { z } from "zod";
import { type Lister, withParam } from "../list-models.js";
import { apiKeyMode } from "./api-key.js";
import type { ProviderDef } from "./provider.js";

const PAGE = z.object({
	models: z.array(z.object({
		name: z.string(),
		displayName: z.string(),
	})).default([]),
	nextPageToken: z.string().optional(),
});

// Google's names start with "models/", which the SDK doesn't take.
const LISTER: Lister = {
	url: "https://generativelanguage.googleapis.com/v1beta/models?pageSize=1000",
	headers: (apiKey) => ({ "x-goog-api-key": apiKey }),
	parse: (body, url) => {
		const page = PAGE.parse(body);

		return {
			models: page.models.map(({ name, displayName }) => ({ id: name.replace(/^models\//, ""), name: displayName })),
			next: page.nextPageToken === undefined ? undefined : withParam(url, "pageToken", page.nextPageToken),
		};
	},
};

export const google: ProviderDef = {
	name: "google",
	modes: {
		"api-key": apiKeyMode("google", (apiKey) => createGoogle({ apiKey }), LISTER),
	},
};
