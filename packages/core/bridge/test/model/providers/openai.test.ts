// Tests for model/providers/openai.ts: its model lists, with an API key and
// on a ChatGPT plan, with a fake fetch.

import { describe, expect, test } from "vitest";
import { listModels } from "../../../src/model/list-models.js";
import { SUBSCRIPTION_LISTER, openai } from "../../../src/model/providers/openai.js";
import type { ModeSupport } from "../../../src/model/providers/provider.js";
import { type Call, fakeFetch } from "../fake-fetch.js";
import { configWithKeys } from "../fake-providers.js";

const URL = "https://api.openai.com/v1/models";
const CONFIG = configWithKeys({ openai: { apiKey: "key" } });
const mode = openai.modes["api-key"] as ModeSupport;

test("keeps every model without a date, newest first", async () => {
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

	expect(await mode.listModels(CONFIG, fetchPage)).toEqual({
		ok: true,
		models: [
			{ id: "gpt-new", name: "gpt-new" },
			{ id: "gpt-new-tts", name: "gpt-new-tts" },
			{ id: "gpt-image-2", name: "gpt-image-2" },
			{ id: "text-embedding-3-small", name: "text-embedding-3-small" },
			{ id: "whisper-1", name: "whisper-1" },
			{ id: "o9-mini", name: "o9-mini" },
			{ id: "gpt-old", name: "gpt-old" },
			{ id: "gpt-4.1-mini", name: "gpt-4.1-mini" },
		],
	});
});

test("sends the key as a bearer token", async () => {
	const calls: Call[] = [];

	await mode.listModels(CONFIG, fakeFetch({ [URL]: { data: [] } }, calls));

	expect(calls[0].headers).toEqual({ Authorization: "Bearer key" });
});

test("fails on an answer of the wrong shape", async () => {
	const result = await mode.listModels(CONFIG, fakeFetch({ [URL]: { models: [] } }));

	expect(result).toMatchObject({ ok: false, error: expect.stringMatching(/^Couldn't list the openai models: /) as unknown });
});

describe("on a ChatGPT plan", () => {
	test("keeps the models marked list, in OpenAI's order, with their display names", async () => {
		const calls: Call[] = [];
		const fetchPage = fakeFetch({
			[URL]: {
				models: [
					{ slug: "gpt-new", display_name: "GPT New", visibility: "list" },
					{ slug: "gpt-hidden", display_name: "GPT Hidden", visibility: "hide" },
					{ slug: "gpt-old", display_name: "GPT Old", visibility: "list" },
				],
			},
		}, calls);

		expect(await listModels("openai", SUBSCRIPTION_LISTER, "token", fetchPage)).toEqual({
			ok: true,
			models: [{ id: "gpt-new", name: "GPT New" }, { id: "gpt-old", name: "GPT Old" }],
		});
		expect(calls[0].headers).toEqual({ Authorization: "Bearer token" });
	});

	test("fails on the API key mode's shape", async () => {
		const result = await listModels("openai", SUBSCRIPTION_LISTER, "token", fakeFetch({ [URL]: { data: [] } }));

		expect(result).toMatchObject({ ok: false, error: expect.stringMatching(/^Couldn't list the openai models: /) as unknown });
	});
});
