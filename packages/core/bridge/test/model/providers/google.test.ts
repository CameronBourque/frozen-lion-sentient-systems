// Tests for model/providers/google.ts: its model list, with a fake fetch.

import { expect, test } from "vitest";
import { google } from "../../../src/model/providers/google.js";
import type { ModeSupport } from "../../../src/model/providers/provider.js";
import { type Call, fakeFetch } from "../fake-fetch.js";
import { configWithKeys } from "../fake-providers.js";

const FIRST = "https://generativelanguage.googleapis.com/v1beta/models?pageSize=1000";
const SECOND = "https://generativelanguage.googleapis.com/v1beta/models?pageSize=1000&pageToken=next";
const CONFIG = configWithKeys({ google: { apiKey: "key" } });
const mode = google.modes["api-key"] as ModeSupport;

test("lists every model across pages, without the models/ prefix", async () => {
	const calls: Call[] = [];
	const fetchPage = fakeFetch({
		[FIRST]: {
			models: [
				{ name: "models/gemini-pro", displayName: "Gemini Pro" },
				{ name: "models/gemini-embedding", displayName: "Embedding" },
			],
			nextPageToken: "next",
		},
		[SECOND]: { models: [{ name: "models/gemini-flash", displayName: "Gemini Flash" }] },
	}, calls);

	expect(await mode.listModels(CONFIG, fetchPage)).toEqual({
		ok: true,
		models: [{ id: "gemini-pro", name: "Gemini Pro" }, { id: "gemini-embedding", name: "Embedding" }, { id: "gemini-flash", name: "Gemini Flash" }],
	});
	expect(calls[0].headers).toEqual({ "x-goog-api-key": "key" });
});

test("reads a page with no models", async () => {
	expect(await mode.listModels(CONFIG, fakeFetch({ [FIRST]: {} }))).toEqual({ ok: true, models: [] });
});
