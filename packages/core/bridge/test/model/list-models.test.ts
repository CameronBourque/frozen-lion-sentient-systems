// Tests for model/list-models.ts: the failures that every provider's list
// shares, with a fake fetch and a one-page lister.

import { describe, expect, test } from "vitest";
import { type Fetch, type Lister, listModels } from "../../src/model/list-models.js";
import { fakeFetch } from "./fake-fetch.js";

const LISTER: Lister = {
	url: "https://example.com/models",
	headers: (apiKey) => ({ key: apiKey }),
	parse: () => ({ models: [] }),
};

describe("failures", () => {
	test("names the status when the provider refuses", async () => {
		expect(await listModels("openai", LISTER, "bad", fakeFetch({}))).toEqual({
			ok: false,
			error: "openai answered the model list with 404: Not Found",
		});
	});

	test("gives the provider's own reason when its answer has one", async () => {
		const refuse: Fetch = () => Promise.resolve(new Response(
			JSON.stringify({ type: "error", error: { type: "authentication_error", message: "invalid x-api-key" } }),
			{ status: 401 },
		));

		expect(await listModels("anthropic", LISTER, "bad", refuse)).toEqual({
			ok: false,
			error: "anthropic answered the model list with 401: invalid x-api-key",
		});
	});

	test("gives only the status when there is no reason", async () => {
		const refuse: Fetch = () => Promise.resolve(new Response("", { status: 401 }));

		expect(await listModels("anthropic", LISTER, "bad", refuse)).toEqual({ ok: false, error: "anthropic answered the model list with 401" });
	});

	test("names the reason when the request fails", async () => {
		const offline: Fetch = () => Promise.reject(new Error("getaddrinfo ENOTFOUND"));

		expect(await listModels("anthropic", LISTER, "key", offline)).toEqual({
			ok: false,
			error: "Couldn't list the anthropic models: getaddrinfo ENOTFOUND",
		});
	});
});
