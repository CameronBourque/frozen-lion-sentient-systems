// OpenAI, in each run mode it supports.
// docs/design/core/run-modes.md has the design.

import { createOpenAI } from "@ai-sdk/openai";
import { APICallError, type LanguageModelMiddleware, wrapLanguageModel } from "ai";
import { z } from "zod";
import { USAGE_LIMIT_CODE, hasCode } from "../client.js";
import type { Lister } from "../list-models.js";
import type { OpenAITokens } from "../sign-in/openai-tokens.js";
import { apiKeyMode } from "./api-key.js";
import { type Credential, credentialMode } from "./mode.js";
import type { ModeSupport, ProviderDef } from "./provider.js";

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

export type Send = (input: RequestInfo | URL, init?: RequestInit) => Promise<Response>;

function withToken(init: RequestInit | undefined, token: string): RequestInit {
	const headers = new Headers(init?.headers);

	headers.set("Authorization", `Bearer ${token}`);

	return { ...init, headers };
}

// Sets the plan's current token on each request, because a game outlasts a
// token. A 401 refreshes once and sends again, unless the refresh fails. A
// token that can't refresh fails the call with the refresh's reason.
function subscriptionFetch(tokens: OpenAITokens, send: Send = fetch): Send {
	return async (input, init) => {
		const current = await tokens.secret();

		if (!current.ok) {
			throw new Error(current.error);
		}

		const response = await send(input, withToken(init, current.secret));

		if (response.status !== 401) {
			return response;
		}

		const fresh = await tokens.refreshAfterRefusal(current.secret);

		return fresh.ok ? send(input, withToken(init, fresh.secret)) : response;
	};
}

// The plan rejects a system message and stored responses, so the system
// prompt goes in OpenAI's instructions. A usage limit isn't retried, because
// every retry fails until the plan resets.
const SUBSCRIPTION_MIDDLEWARE: LanguageModelMiddleware = {
	transformParams: ({ params }) => Promise.resolve({
		...params,
		prompt: params.prompt.filter(({ role }) => role !== "system"),
		providerOptions: {
			...params.providerOptions,
			openai: {
				...params.providerOptions?.openai,
				store: false,
				instructions: params.prompt.flatMap((message) => message.role === "system" ? [message.content] : []).join("\n\n"),
			},
		},
	}),
	wrapStream: async ({ doStream }) => {
		try {
			return await doStream();
		} catch (error) {
			if (hasCode(USAGE_LIMIT_CODE)(error)) {
				throw new APICallError({ ...error, message: error.message, isRetryable: false });
			}

			throw error;
		}
	},
};

function subscriptionCredential(tokens: OpenAITokens): Credential<OpenAITokens> {
	return {
		ready: () => tokens.signedIn() ? { ok: true } : { ok: false, reason: "Not signed in to a ChatGPT plan" },
		source: () => tokens,
		secret: (store) => store.secret(),
	};
}

// The SDK needs an API key, which the plan's fetch replaces with the token.
export function subscriptionMode(tokens: OpenAITokens, send: Send = fetch): ModeSupport {
	const factory = (store: OpenAITokens) => (modelId: string) => wrapLanguageModel({
		model: createOpenAI({ apiKey: "chatgpt-plan", fetch: subscriptionFetch(store, send) })(modelId),
		middleware: SUBSCRIPTION_MIDDLEWARE,
	});

	return credentialMode("openai", subscriptionCredential(tokens), factory, SUBSCRIPTION_LISTER);
}

export const openai: ProviderDef = {
	name: "openai",
	modes: {
		"api-key": apiKeyMode("openai", (apiKey) => createOpenAI({ apiKey }), API_KEY_LISTER),
	},
};
