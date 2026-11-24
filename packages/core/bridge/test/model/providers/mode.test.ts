// Tests for model/providers/mode.ts: a mode built from a credential whose
// value isn't a string, as a plan's token source isn't.

import { MockLanguageModelV4 } from "ai/test";
import { expect, test } from "vitest";
import type { Lister } from "../../../src/model/list-models.js";
import { type Credential, credentialMode } from "../../../src/model/providers/mode.js";
import { type Call, fakeFetch } from "../fake-fetch.js";
import { configWithKeys } from "../fake-providers.js";

interface TokenSource {
	signedIn: boolean;
	token: string;
}

const URL = "https://api.example.com/models";

const LISTER: Lister = {
	url: URL,
	headers: (credential) => ({ Authorization: `Bearer ${credential}` }),
	parse: () => ({ models: [{ id: "model-a", name: "Model A" }] }),
};

function credentialFor(source: TokenSource): Credential<TokenSource> {
	return {
		ready: () => source.signedIn ? { ok: true } : { ok: false, reason: "Not signed in" },
		value: () => source,
		current: (value) => Promise.resolve(value.token),
	};
}

// A factory that records the value it was given.
function recordingFactory(seen: TokenSource[]) {
	return (value: TokenSource) => (modelId: string) => {
		seen.push(value);

		return new MockLanguageModelV4({ modelId });
	};
}

const CONFIG = configWithKeys({});

test("lists the models with the credential's current string", async () => {
	const calls: Call[] = [];
	const mode = credentialMode("openai", credentialFor({ signedIn: true, token: "token-1" }), recordingFactory([]), LISTER);

	expect(await mode.listModels(CONFIG, fakeFetch({ [URL]: {} }, calls))).toEqual({ ok: true, models: [{ id: "model-a", name: "Model A" }] });
	expect(calls[0].headers).toEqual({ Authorization: "Bearer token-1" });
});

test("builds the model from the credential's value", () => {
	const source = { signedIn: true, token: "token-1" };
	const seen: TokenSource[] = [];
	const mode = credentialMode("openai", credentialFor(source), recordingFactory(seen), LISTER);

	expect(mode.ready(CONFIG)).toEqual({ ok: true });
	expect(mode.model(CONFIG, "model-a")).toMatchObject({ ok: true, model: { modelId: "model-a" } });
	expect(seen).toEqual([source]);
});

test("builds no model when the credential isn't ready", () => {
	const seen: TokenSource[] = [];
	const mode = credentialMode("openai", credentialFor({ signedIn: false, token: "" }), recordingFactory(seen), LISTER);

	expect(mode.ready(CONFIG)).toEqual({ ok: false, reason: "Not signed in" });
	expect(mode.model(CONFIG, "model-a")).toEqual({ ok: false, error: "Not signed in" });
	expect(seen).toEqual([]);
});
