// Tests for model/providers/anthropic.ts: its model list, with a fake fetch.

import { expect, test } from "vitest";
import { anthropic } from "../../../src/model/providers/anthropic.js";
import type { ModeSupport } from "../../../src/model/providers/provider.js";
import { type Call, fakeFetch } from "../fake-fetch.js";
import { configWithKeys } from "../fake-providers.js";

const FIRST = "https://api.anthropic.com/v1/models?limit=1000";
const SECOND = "https://api.anthropic.com/v1/models?limit=1000&after_id=claude-b";

test("lists every page, with the key and the API version", async () => {
	const calls: Call[] = [];
	const fetchPage = fakeFetch({
		[FIRST]: { data: [{ id: "claude-a", display_name: "Claude A" }, { id: "claude-b", display_name: "Claude B" }], has_more: true, last_id: "claude-b" },
		[SECOND]: { data: [{ id: "claude-c", display_name: "Claude C" }], has_more: false, last_id: "claude-c" },
	}, calls);
	const mode = anthropic.modes["api-key"] as ModeSupport;

	expect(await mode.listModels(configWithKeys({ anthropic: { apiKey: "key" } }), fetchPage)).toEqual({
		ok: true,
		models: [{ id: "claude-a", name: "Claude A" }, { id: "claude-b", name: "Claude B" }, { id: "claude-c", name: "Claude C" }],
	});
	expect(calls.map(({ url }) => url)).toEqual([FIRST, SECOND]);
	expect(calls[0].headers).toEqual({ "x-api-key": "key", "anthropic-version": "2023-06-01" });
});
