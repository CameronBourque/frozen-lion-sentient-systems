// Tests for model/providers/xai.ts: its model list, with a fake fetch.

import { expect, test } from "vitest";
import { xai } from "../../../src/model/providers/xai.js";
import type { ModeSupport } from "../../../src/model/providers/provider.js";
import { type Call, fakeFetch } from "../fake-fetch.js";
import { configWithKeys } from "../fake-providers.js";

const URL = "https://api.x.ai/v1/language-models";
const CONFIG = configWithKeys({ xai: { apiKey: "key" } });
const mode = xai.modes["api-key"] as ModeSupport;

test("lists the language models, newest first", async () => {
	const calls: Call[] = [];
	const fetchPage = fakeFetch({
		[URL]: {
			models: [
				{ id: "grok-old", created: 1700000000, aliases: [] },
				{ id: "grok-new", created: 1776556800, aliases: ["grok-latest"] },
			],
		},
	}, calls);

	expect(await mode.listModels(CONFIG, fetchPage)).toEqual({
		ok: true,
		models: [{ id: "grok-new", name: "grok-new" }, { id: "grok-old", name: "grok-old" }],
	});
	expect(calls[0].headers).toEqual({ Authorization: "Bearer key" });
});
