// OpenAI, in each run mode it supports.
// docs/design/core/run-modes.md has the design.

import { createOpenAI } from "@ai-sdk/openai";
import { z } from "zod";
import type { Lister } from "../list-models.js";
import { apiKeyMode } from "./api-key.js";
import type { ProviderDef } from "./provider.js";

// OpenAI lists each dated snapshot beside its alias, which doubles the menu.
// Newer snapshots end in the full date, and older ones in the month and day,
// some with "-preview" after it.
const FULL_DATE = String.raw`\d{4}-\d{2}-\d{2}`;
const MONTH_AND_DAY = String.raw`\d{4}`;
const DATED = new RegExp(`-(${FULL_DATE}|${MONTH_AND_DAY})(-preview)?$`);

const API_KEY_PAGE = z.object({
	data: z.array(z.object({ id: z.string(), created: z.number() })),
});

// OpenAI lists every model in one page.
const API_KEY_LISTER: Lister = {
	url: "https://api.openai.com/v1/models",
	headers: (credential) => ({ Authorization: `Bearer ${credential}` }),
	parse: (body) => ({
		models: API_KEY_PAGE.parse(body).data
			.filter(({ id }) => !DATED.test(id))
			.sort((a, b) => b.created - a.created)
			.map(({ id }) => ({ id, name: id })),
	}),
};

const SUBSCRIPTION_PAGE = z.object({
	models: z.array(z.object({ slug: z.string(), display_name: z.string(), visibility: z.string() })),
});

// On a ChatGPT plan, the same URL answers with the plan's own shape, in
// OpenAI's order. A model it doesn't mark "list" isn't for the user to pick.
export const SUBSCRIPTION_LISTER: Lister = {
	url: API_KEY_LISTER.url,
	headers: API_KEY_LISTER.headers,
	parse: (body) => ({
		models: SUBSCRIPTION_PAGE.parse(body).models
			.filter(({ visibility }) => visibility === "list")
			.map(({ slug, display_name }) => ({ id: slug, name: display_name })),
	}),
};

export const openai: ProviderDef = {
	name: "openai",
	modes: {
		"api-key": apiKeyMode("openai", (apiKey) => createOpenAI({ apiKey }), API_KEY_LISTER),
	},
};
