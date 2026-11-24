// Tests for the subscription mode in model/providers/openai.ts: the token on
// each request, the retry after a 401, and the request the plan accepts, with
// a fake token store and a fake send.

import { expect, test } from "vitest";
import { type ModelRequest, callModel } from "../../../src/model/client.js";
import { type Send, subscriptionMode } from "../../../src/model/providers/openai.js";
import type { OpenAITokens } from "../../../src/model/sign-in/openai-tokens.js";
import { type Call, fakeFetch } from "../fake-fetch.js";
import { configWithKeys } from "../fake-providers.js";

const CONFIG = configWithKeys({});

const REQUEST: ModelRequest = {
	system: "You play Civilization VI.",
	messages: [{ role: "user", content: "Your turn." }],
	tools: [],
};

interface Sent {
	url: string;
	authorization: string | null;
	body: Record<string, unknown>;
}

// A store whose secret hands out each token in turn, and whose refresh after
// a refusal hands out the next.
function fakeTokens(tokens: string[], { signedIn = true, refreshError = "" } = {}): OpenAITokens & { refused: string[] } {
	const refused: string[] = [];
	let current = 0;
	const secretAt = (index: number) => Promise.resolve(index < tokens.length ? { ok: true as const, secret: tokens[index] } : { ok: false as const, error: "Sign in again" });

	return {
		refused,
		signedIn: () => signedIn,
		secret: () => secretAt(current),
		refreshAfterRefusal: (rejected) => {
			refused.push(rejected);
			current += 1;

			return refreshError === "" ? secretAt(current) : Promise.resolve({ ok: false, error: refreshError });
		},
		signInHints: () => {
			throw new Error("unused");
		},
		saveSignIn: () => {
			throw new Error("unused");
		},
	};
}

function json(body: unknown, status: number): Response {
	return new Response(JSON.stringify(body), { status, headers: { "content-type": "application/json" } });
}

// A send that records each request and answers with each reply in turn.
function recordingSend(replies: Response[], sent: Sent[]): Send {
	return (input, init) => {
		sent.push({
			url: String(input),
			authorization: new Headers(init?.headers).get("Authorization"),
			body: JSON.parse(String(init?.body)) as Record<string, unknown>,
		});

		return Promise.resolve(replies.shift() ?? json({ error: { message: "No reply left" } }, 400));
	};
}

async function call(tokens: OpenAITokens, replies: Response[], sent: Sent[]) {
	const built = subscriptionMode(tokens, recordingSend(replies, sent)).model(CONFIG, "gpt-plan");

	if (!built.ok) {
		throw new Error(built.error);
	}

	return callModel({ model: built.model, provider: "openai", mode: "subscription", effort: "" }, REQUEST);
}

test("sends the token, store false, and the system prompt as instructions", async () => {
	const sent: Sent[] = [];

	await call(fakeTokens(["token-1"]), [json({ error: { message: "Bad request" } }, 400)], sent);

	expect(sent[0].url).toBe("https://api.openai.com/v1/responses");
	expect(sent[0].authorization).toBe("Bearer token-1");
	expect(sent[0].body).toMatchObject({ model: "gpt-plan", store: false, stream: true, instructions: "You play Civilization VI." });
	expect(sent[0].body.input).toEqual([{ role: "user", content: [{ type: "input_text", text: "Your turn." }] }]);
});

test("refreshes once after a 401 and sends again with the new token", async () => {
	const sent: Sent[] = [];
	const tokens = fakeTokens(["token-1", "token-2"]);

	await call(tokens, [json({ error: { message: "Expired" } }, 401), json({ error: { message: "Bad request" } }, 400)], sent);

	expect(tokens.refused).toEqual(["token-1"]);
	expect(sent.map(({ authorization }) => authorization)).toEqual(["Bearer token-1", "Bearer token-2"]);
});

test("fails as auth when the refresh after a 401 fails", async () => {
	const sent: Sent[] = [];

	const result = await call(fakeTokens(["token-1"], { refreshError: "Spent" }), [json({ error: { message: "Expired" } }, 401)], sent);

	expect(result).toMatchObject({ ok: false, kind: "auth", error: expect.stringMatching(/Sign in again from the Run mode menu$/) as unknown });
	expect(sent).toHaveLength(1);
});

test("fails with the refresh's reason and sends nothing when the token can't refresh", async () => {
	const sent: Sent[] = [];

	expect(await call(fakeTokens([]), [], sent)).toEqual({ ok: false, kind: "other", error: "The openai model call failed: Sign in again" });
	expect(sent).toEqual([]);
});

test("doesn't retry a usage limit", async () => {
	const sent: Sent[] = [];
	const limit = json({ error: { code: "subscription_sharing_usage_limit_exceeded", message: "Usage limit reached" } }, 429);

	expect(await call(fakeTokens(["token-1"]), [limit], sent)).toMatchObject({ ok: false, kind: "limit" });
	expect(sent).toHaveLength(1);
});

test("lists the plan's models with the current token", async () => {
	const calls: Call[] = [];
	const fetchPage = fakeFetch({ "https://api.openai.com/v1/models": { models: [{ slug: "gpt-plan", display_name: "GPT Plan", visibility: "list" }] } }, calls);

	expect(await subscriptionMode(fakeTokens(["token-1"])).listModels(CONFIG, fetchPage)).toEqual({ ok: true, models: [{ id: "gpt-plan", name: "GPT Plan" }] });
	expect(calls[0].headers).toEqual({ Authorization: "Bearer token-1" });
});

test("isn't ready until signed in", () => {
	expect(subscriptionMode(fakeTokens([], { signedIn: false })).ready(CONFIG)).toEqual({ ok: false, reason: "Not signed in to a ChatGPT plan" });
});
