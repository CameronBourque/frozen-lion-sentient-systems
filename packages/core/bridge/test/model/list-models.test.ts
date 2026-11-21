// Tests for model/list-models.ts, with a fake fetch that answers each URL from
// a table of pages.

import { describe, expect, test } from "vitest";
import { type Fetch, listModels } from "../../src/model/list-models.js";

interface Call {
	url: string;
	headers: Record<string, string>;
}

// Answers each URL with its page, and records the calls.
function fakeFetch(pages: Record<string, unknown>, calls: Call[] = []): Fetch {
	return (url, init) => {
		calls.push({ url, headers: init.headers });

		return Promise.resolve(url in pages
			? new Response(JSON.stringify(pages[url]))
			: new Response("", { status: 404, statusText: "Not Found" }));
	};
}

describe("anthropic", () => {
	const FIRST = "https://api.anthropic.com/v1/models?limit=1000";
	const SECOND = "https://api.anthropic.com/v1/models?limit=1000&after_id=claude-b";

	test("lists every page, with the key and the API version", async () => {
		const calls: Call[] = [];
		const fetchPage = fakeFetch({
			[FIRST]: { data: [{ id: "claude-a", display_name: "Claude A" }, { id: "claude-b", display_name: "Claude B" }], has_more: true, last_id: "claude-b" },
			[SECOND]: { data: [{ id: "claude-c", display_name: "Claude C" }], has_more: false, last_id: "claude-c" },
		}, calls);

		expect(await listModels("anthropic", "key", fetchPage)).toEqual({
			ok: true,
			models: [{ id: "claude-a", name: "Claude A" }, { id: "claude-b", name: "Claude B" }, { id: "claude-c", name: "Claude C" }],
		});
		expect(calls.map(({ url }) => url)).toEqual([FIRST, SECOND]);
		expect(calls[0].headers).toEqual({ "x-api-key": "key", "anthropic-version": "2023-06-01" });
	});
});

describe("openai", () => {
	const URL = "https://api.openai.com/v1/models";

	test("keeps the chat models without a date, newest first", async () => {
		const fetchPage = fakeFetch({
			[URL]: {
				data: [
					{ id: "gpt-old", created: 1 },
					{ id: "gpt-new", created: 3 },
					{ id: "o9-mini", created: 2 },
					{ id: "gpt-new-2026-01-02", created: 3 },
					{ id: "gpt-old-0125", created: 1 },
					{ id: "gpt-old-1106-preview", created: 1 },
					{ id: "gpt-4.1-mini", created: 0 },
					{ id: "gpt-new-tts", created: 3 },
					{ id: "gpt-image-2", created: 3 },
					{ id: "text-embedding-3-small", created: 3 },
					{ id: "whisper-1", created: 3 },
				],
			},
		});

		expect(await listModels("openai", "key", fetchPage)).toEqual({
			ok: true,
			models: [
				{ id: "gpt-new", name: "gpt-new" },
				{ id: "o9-mini", name: "o9-mini" },
				{ id: "gpt-old", name: "gpt-old" },
				{ id: "gpt-4.1-mini", name: "gpt-4.1-mini" },
			],
		});
	});

	test("sends the key as a bearer token", async () => {
		const calls: Call[] = [];

		await listModels("openai", "key", fakeFetch({ [URL]: { data: [] } }, calls));

		expect(calls[0].headers).toEqual({ Authorization: "Bearer key" });
	});
});

describe("google", () => {
	const FIRST = "https://generativelanguage.googleapis.com/v1beta/models?pageSize=1000";
	const SECOND = "https://generativelanguage.googleapis.com/v1beta/models?pageSize=1000&pageToken=next";
	const CHAT = ["generateContent", "countTokens"];

	test("keeps the Gemini models that generate content, across pages", async () => {
		const calls: Call[] = [];
		const fetchPage = fakeFetch({
			[FIRST]: {
				models: [
					{ name: "models/gemini-pro", displayName: "Gemini Pro", supportedGenerationMethods: CHAT },
					{ name: "models/gemini-pro-tts", displayName: "Gemini TTS", supportedGenerationMethods: CHAT },
					{ name: "models/gemma-3", displayName: "Gemma 3", supportedGenerationMethods: CHAT },
					{ name: "models/gemini-embedding", displayName: "Embedding", supportedGenerationMethods: ["embedContent"] },
				],
				nextPageToken: "next",
			},
			[SECOND]: { models: [{ name: "models/gemini-flash", displayName: "Gemini Flash", supportedGenerationMethods: CHAT }] },
		}, calls);

		expect(await listModels("google", "key", fetchPage)).toEqual({
			ok: true,
			models: [{ id: "gemini-pro", name: "Gemini Pro" }, { id: "gemini-flash", name: "Gemini Flash" }],
		});
		expect(calls[0].headers).toEqual({ "x-goog-api-key": "key" });
	});

	test("reads a page with no models", async () => {
		expect(await listModels("google", "key", fakeFetch({ [FIRST]: {} }))).toEqual({ ok: true, models: [] });
	});
});

describe("failures", () => {
	test("names the status when the provider refuses", async () => {
		expect(await listModels("openai", "bad", fakeFetch({}))).toEqual({
			ok: false,
			error: "openai answered the model list with 404 Not Found",
		});
	});

	test("names the reason when the request fails", async () => {
		const offline: Fetch = () => Promise.reject(new Error("getaddrinfo ENOTFOUND"));

		expect(await listModels("anthropic", "key", offline)).toEqual({
			ok: false,
			error: "Couldn't list the anthropic models: getaddrinfo ENOTFOUND",
		});
	});

	test("fails on an answer of the wrong shape", async () => {
		const result = await listModels("openai", "key", fakeFetch({ "https://api.openai.com/v1/models": { models: [] } }));

		expect(result).toMatchObject({ ok: false, error: expect.stringMatching(/^Couldn't list the openai models: /) as unknown });
	});
});
