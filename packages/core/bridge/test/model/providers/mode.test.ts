// Tests for model/providers/mode.ts: a mode built from a credential whose
// source isn't a string, as a plan's token store isn't.

import { MockLanguageModelV4 } from "ai/test";
import { expect, test } from "vitest";
import type { Lister } from "../../../src/model/list-models.js";
import { type Credential, credentialMode } from "../../../src/model/providers/mode.js";
import { type Call, fakeFetch } from "../fake-fetch.js";
import { configWithKeys } from "../fake-providers.js";

interface TokenSource {
	signedIn: boolean;
	token: string;
	refreshError?: string;
}

const URL = "https://api.example.com/models";

const LISTER: Lister = {
	url: URL,
	headers: (secret) => ({ Authorization: `Bearer ${secret}` }),
	parse: () => ({ models: [{ id: "model-a", name: "Model A" }] }),
};

function credentialFor(source: TokenSource): Credential<TokenSource> {
	return {
		ready: () => source.signedIn ? { ok: true } : { ok: false, reason: "Not signed in" },
		source: () => source,
		secret: ({ token, refreshError }) => Promise.resolve(refreshError === undefined ? { ok: true, secret: token } : { ok: false, error: refreshError }),
	};
}

// A factory that records the source it was given.
function recordingFactory(seen: TokenSource[]) {
	return (source: TokenSource) => (modelId: string) => {
		seen.push(source);

		return new MockLanguageModelV4({ modelId });
	};
}

const CONFIG = configWithKeys({});

test("lists the models with the credential's secret", async () => {
	const calls: Call[] = [];
	const mode = credentialMode("openai", "subscription", credentialFor({ signedIn: true, token: "token-1" }), recordingFactory([]), LISTER);

	expect(await mode.listModels(CONFIG, fakeFetch({ [URL]: {} }, calls))).toEqual({ ok: true, models: [{ id: "model-a", name: "Model A" }] });
	expect(calls[0].headers).toEqual({ Authorization: "Bearer token-1" });
});

test("fails the list with the credential's error, with no request", async () => {
	const calls: Call[] = [];
	const mode = credentialMode("openai", "subscription", credentialFor({ signedIn: true, token: "", refreshError: "Sign in again" }), recordingFactory([]), LISTER);

	expect(await mode.listModels(CONFIG, fakeFetch({ [URL]: {} }, calls))).toEqual({ ok: false, error: "Sign in again" });
	expect(calls).toEqual([]);
});

test("builds the model from the credential's source", () => {
	const source = { signedIn: true, token: "token-1" };
	const seen: TokenSource[] = [];
	const mode = credentialMode("openai", "subscription", credentialFor(source), recordingFactory(seen), LISTER);

	expect(mode.ready(CONFIG)).toEqual({ ok: true });
	expect(mode.model(CONFIG, "model-a")).toMatchObject({ ok: true, model: { modelId: "model-a" } });
	expect(seen).toEqual([source]);
});

test("builds no model when the credential isn't ready", () => {
	const seen: TokenSource[] = [];
	const mode = credentialMode("openai", "subscription", credentialFor({ signedIn: false, token: "" }), recordingFactory(seen), LISTER);

	expect(mode.ready(CONFIG)).toEqual({ ok: false, reason: "Not signed in" });
	expect(mode.model(CONFIG, "model-a")).toEqual({ ok: false, error: "Not signed in" });
	expect(seen).toEqual([]);
});
