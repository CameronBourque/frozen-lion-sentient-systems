// Lists a provider's models through its own API, keeping the ones that write
// text and call tools. docs/design/core/model-client.md has the design.

import { z } from "zod";
import type { Provider } from "../config.js";

export interface ModelInfo {
	id: string;
	name: string;
}

export type ListResult =
	| { ok: true; models: ModelInfo[] }
	| { ok: false; error: string };

export type Fetch = (url: string, init: { headers: Record<string, string> }) => Promise<Response>;

// One page of a list, and the URL of the next page, if any.
interface Page {
	models: ModelInfo[];
	next?: string;
}

interface Lister {
	url: string;
	headers: (apiKey: string) => Record<string, string>;
	parse: (body: unknown, url: string) => Page;
}

// Words in the ID of a model that doesn't chat with tools, such as speech,
// image, or embedding models.
const NOT_CHAT = /audio|realtime|tts|transcribe|image|embedding|search|moderation|instruct|live|robotics|computer-use/;

// OpenAI lists each dated snapshot beside its alias, which doubles the menu.
// Newer snapshots end in the full date, and older ones in the month and day,
// some with "-preview" after it.
const FULL_DATE = String.raw`\d{4}-\d{2}-\d{2}`;
const MONTH_AND_DAY = String.raw`\d{4}`;
const DATED = new RegExp(`-(${FULL_DATE}|${MONTH_AND_DAY})(-preview)?$`);

const ANTHROPIC_PAGE = z.object({
	data: z.array(z.object({ id: z.string(), display_name: z.string() })),
	has_more: z.boolean(),
	last_id: z.string().nullable(),
});

const OPENAI_PAGE = z.object({
	data: z.array(z.object({ id: z.string(), created: z.number() })),
});

const GOOGLE_PAGE = z.object({
	models: z.array(z.object({
		name: z.string(),
		displayName: z.string(),
		supportedGenerationMethods: z.array(z.string()).default([]),
	})).default([]),
	nextPageToken: z.string().optional(),
});

// Replaces one query parameter, for the next page.
function withParam(url: string, name: string, value: string): string {
	const next = new URL(url);

	next.searchParams.set(name, value);

	return next.toString();
}

const LISTERS: Record<Provider, Lister> = {
	// Anthropic lists only chat models, newest first.
	anthropic: {
		url: "https://api.anthropic.com/v1/models?limit=1000",
		headers: (apiKey) => ({ "x-api-key": apiKey, "anthropic-version": "2023-06-01" }),
		parse: (body, url) => {
			const page = ANTHROPIC_PAGE.parse(body);

			return {
				models: page.data.map(({ id, display_name }) => ({ id, name: display_name })),
				next: page.has_more && page.last_id !== null ? withParam(url, "after_id", page.last_id) : undefined,
			};
		},
	},
	// OpenAI lists every kind of model in one page, with no capabilities, so
	// the ID is all there is to go on.
	openai: {
		url: "https://api.openai.com/v1/models",
		headers: (apiKey) => ({ Authorization: `Bearer ${apiKey}` }),
		parse: (body) => ({
			models: OPENAI_PAGE.parse(body).data
				.filter(({ id }) => /^(gpt-|o\d)/.test(id) && !NOT_CHAT.test(id) && !DATED.test(id))
				.sort((a, b) => b.created - a.created)
				.map(({ id }) => ({ id, name: id })),
		}),
	},
	// Google's names start with "models/", which the SDK doesn't take.
	google: {
		url: "https://generativelanguage.googleapis.com/v1beta/models?pageSize=1000",
		headers: (apiKey) => ({ "x-goog-api-key": apiKey }),
		parse: (body, url) => {
			const page = GOOGLE_PAGE.parse(body);

			return {
				models: page.models
					.map((model) => ({ ...model, id: model.name.replace(/^models\//, "") }))
					.filter(({ id, supportedGenerationMethods }) =>
						id.startsWith("gemini-") && !NOT_CHAT.test(id) && supportedGenerationMethods.includes("generateContent"))
					.map(({ id, displayName }) => ({ id, name: displayName })),
				next: page.nextPageToken === undefined ? undefined : withParam(url, "pageToken", page.nextPageToken),
			};
		},
	},
};

// Fetches every page. A failed request or an unexpected answer fails the
// whole list, with a reason the picker can show.
export async function listModels(provider: Provider, apiKey: string, fetchPage: Fetch = fetch): Promise<ListResult> {
	const lister = LISTERS[provider];
	const models: ModelInfo[] = [];
	let url: string | undefined = lister.url;

	try {
		while (url !== undefined) {
			const response = await fetchPage(url, { headers: lister.headers(apiKey) });

			if (!response.ok) {
				return { ok: false, error: `${provider} answered the model list with ${response.status} ${response.statusText}` };
			}

			const page = lister.parse(await response.json(), url);

			models.push(...page.models);
			url = page.next;
		}
	} catch (error) {
		// fetch and zod throw only errors.
		return { ok: false, error: `Couldn't list the ${provider} models: ${(error as Error).message}` };
	}

	return { ok: true, models };
}
