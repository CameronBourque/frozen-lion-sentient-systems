// Tests for model/sign-in/openai.ts: a fake browser follows the authorize URL
// back to the real callback server, and fakes stand in for OpenAI's token
// URL and keys.

import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { afterEach, beforeEach, expect, test } from "vitest";
import { DISCOVERY_URL, readCallback, signIn, type SignInIo } from "../../../src/model/sign-in/openai.js";
import { type Post, authFilePath, openAITokens } from "../../../src/model/sign-in/openai-tokens.js";
import { ISSUER, PUBLIC_JWK, signedToken } from "./fake-id-token.js";

const NOW = 1_000_000_000_000;
const HOUR_MS = 3_600_000;
const JWKS_URL = "https://auth.openai.com/jwks";
const HOST_ID = "urn:uuid:00000000-0000-4000-8000-000000000000";
const PLAN_SCOPES = "openid offline_access chatgpt.tokens.use.direct";

let folder: string;

beforeEach(() => {
	folder = fs.mkdtempSync(path.join(os.tmpdir(), "sentient-systems-"));
});

afterEach(() => {
	fs.rmSync(folder, { recursive: true, force: true });
});

function writeAuth(auth: unknown): void {
	fs.mkdirSync(path.join(folder, "auth"));
	fs.writeFileSync(authFilePath(folder), JSON.stringify(auth));
}

function readAuth(): unknown {
	return JSON.parse(fs.readFileSync(authFilePath(folder), "utf8"));
}

function json(body: unknown, status = 200): Response {
	return new Response(JSON.stringify(body), { status });
}

interface Page {
	status: number;
	text: string;
}

// What the fake browser and token URL saw.
interface Seen {
	authorize: URL[];
	pages: Page[];
	forms: Record<string, string>[];
	visits: Promise<void>[];
}

interface Options {
	// The paths and queries the browser visits on the callback server, from
	// the authorize URL.
	visit?: (authorize: URL) => string[];
	// The token URL's reply, from the authorize URL's nonce.
	tokenReply?: (nonce: string) => Response;
	keys?: Response;
	timeoutMs?: number;
}

function callbackQuery(authorize: URL, extra: string): string {
	return `/auth/callback?state=${authorize.searchParams.get("state")}${extra}`;
}

function goodReply(nonce: string, audience = "oaiapp_9"): Response {
	return json({
		access_token: "access-1",
		refresh_token: "refresh-1",
		id_token: signedToken({ iss: ISSUER, aud: audience, exp: NOW / 1000 + 3600, nonce }),
		expires_in: 3600,
		scope: PLAN_SCOPES,
	});
}

function setUp(options: Options = {}): { io: SignInIo; seen: Seen } {
	const seen: Seen = { authorize: [], pages: [], forms: [], visits: [] };
	const visit = options.visit ?? ((authorize) => [callbackQuery(authorize, "&code=code-1&client_id=oaiapp_9")]);
	const tokenReply = options.tokenReply ?? goodReply;

	const post: Post = (_url, init) => {
		seen.forms.push(Object.fromEntries(new URLSearchParams(init.body)));

		// A refresh comes before any authorize URL, so it gets no nonce.
		return Promise.resolve(tokenReply(seen.authorize.at(0)?.searchParams.get("nonce") ?? ""));
	};

	const replies: Record<string, Response> = {
		[DISCOVERY_URL]: json({ issuer: ISSUER, jwks_uri: JWKS_URL }),
		[JWKS_URL]: options.keys ?? json({ keys: [PUBLIC_JWK] }),
	};

	const io: SignInIo = {
		post,
		get: (url) => Promise.resolve(replies[url]),
		now: () => NOW,
		log: { info: () => undefined, warn: () => undefined },
		timeoutMs: options.timeoutMs,
		openBrowser: (url) => {
			const authorize = new URL(url);
			const origin = new URL(authorize.searchParams.get("redirect_uri") ?? "").origin;

			seen.authorize.push(authorize);
			seen.visits.push((async () => {
				for (const target of visit(authorize)) {
					const response = await fetch(`${origin}${target}`);

					seen.pages.push({ status: response.status, text: await response.text() });
				}
			})());
		},
	};

	return { io, seen };
}

async function run(io: SignInIo, seen: Seen) {
	const result = await signIn(openAITokens(folder, io), io);

	await Promise.all(seen.visits);

	return result;
}

test("signs in the first time, registers the bridge, and saves the tokens", async () => {
	const { io, seen } = setUp();

	expect(await run(io, seen)).toEqual({ ok: true, secret: "access-1" });

	const params = Object.fromEntries(seen.authorize[0].searchParams);
	const saved = readAuth() as { hostId: string; idToken: string };

	expect(`${seen.authorize[0].origin}${seen.authorize[0].pathname}`).toBe("https://auth.openai.com/api/accounts/authorize");
	expect(params).toMatchObject({
		client_id: "dynamic_agent_client",
		response_type: "code",
		redirect_uri: expect.stringMatching(/^http:\/\/127\.0\.0\.1:\d+\/auth\/callback$/) as string,
		scope: "openid profile email offline_access resource.invoke chatgpt.tokens.use.direct",
		resource: "https://api.openai.com/v1",
		code_challenge_method: "S256",
		ext_agent_host_id: saved.hostId,
		agent_name_hint: "Sentient Systems",
	});
	expect(params).not.toHaveProperty("id_token_hint");
	expect(saved.hostId).toMatch(/^urn:uuid:[0-9a-f-]{36}$/);
	expect(seen.forms).toEqual([{
		grant_type: "authorization_code",
		client_id: "oaiapp_9",
		code: "code-1",
		code_verifier: expect.any(String) as string,
		redirect_uri: params.redirect_uri,
		resource: "https://api.openai.com/v1",
	}]);
	expect(readAuth()).toEqual({
		schemaVersion: 1,
		hostId: saved.hostId,
		clientId: "oaiapp_9",
		idToken: saved.idToken,
		tokens: { access: "access-1", refresh: "refresh-1", expiresAt: NOW + HOUR_MS, scopes: PLAN_SCOPES.split(" ") },
	});
	expect(seen.pages).toEqual([{ status: 200, text: "Signed in. You can close this tab and go back to the bridge." }]);
});

test("signs in again with the saved client, host ID, and ID token", async () => {
	writeAuth({ schemaVersion: 1, hostId: HOST_ID, clientId: "oaiapp_1", idToken: "id-old" });
	const { io, seen } = setUp({
		visit: (authorize) => [callbackQuery(authorize, "&code=code-1")],
		tokenReply: (nonce) => goodReply(nonce, "oaiapp_1"),
	});

	expect(await run(io, seen)).toEqual({ ok: true, secret: "access-1" });
	expect(Object.fromEntries(seen.authorize[0].searchParams)).toMatchObject({ client_id: "oaiapp_1", ext_agent_host_id: HOST_ID, id_token_hint: "id-old" });
	expect(seen.authorize[0].searchParams.has("agent_name_hint")).toBe(false);
	expect(readAuth()).toMatchObject({ hostId: HOST_ID, clientId: "oaiapp_1" });
});

test("uses a saved token that still works, with no browser", async () => {
	writeAuth({ schemaVersion: 1, hostId: HOST_ID, clientId: "oaiapp_1", tokens: { access: "access-0", refresh: "refresh-0", expiresAt: NOW + HOUR_MS, scopes: [] } });
	const { io, seen } = setUp();

	expect(await run(io, seen)).toEqual({ ok: true, secret: "access-0" });
	expect(seen.authorize).toEqual([]);
});

test("signs in through the browser when the saved refresh token is spent", async () => {
	writeAuth({ schemaVersion: 1, hostId: HOST_ID, clientId: "oaiapp_1", tokens: { access: "access-0", refresh: "refresh-0", expiresAt: NOW, scopes: [] } });
	const { io, seen } = setUp({
		visit: (authorize) => [callbackQuery(authorize, "&code=code-1")],
		tokenReply: (nonce) => nonce === "" ? json({ error: "invalid_grant" }, 400) : goodReply(nonce, "oaiapp_1"),
	});

	expect(await run(io, seen)).toEqual({ ok: true, secret: "access-1" });
	expect(seen.forms.map(({ grant_type }) => grant_type)).toEqual(["refresh_token", "authorization_code"]);
});

test("fails with no browser when a refresh fails and keeps the tokens", async () => {
	writeAuth({ schemaVersion: 1, hostId: HOST_ID, clientId: "oaiapp_1", tokens: { access: "access-0", refresh: "refresh-0", expiresAt: NOW, scopes: [] } });
	const { io, seen } = setUp({ tokenReply: () => json({}, 503) });

	expect(await run(io, seen)).toEqual({ ok: false, error: "OpenAI refused the ChatGPT token request with 503" });
	expect(seen.authorize).toEqual([]);
});

test("keeps waiting past a stray request, then finishes", async () => {
	const { io, seen } = setUp({
		visit: (authorize) => ["/favicon.ico", "/auth/callback?state=old&code=x", callbackQuery(authorize, "&code=code-1&client_id=oaiapp_9")],
	});

	expect(await run(io, seen)).toEqual({ ok: true, secret: "access-1" });
	expect(seen.pages.map(({ status }) => status)).toEqual([404, 404, 200]);
});

test.each([
	["is cancelled", "&error=access_denied", "The ChatGPT sign-in was cancelled"],
	["fails at OpenAI", "&error=server_error", "The ChatGPT sign-in failed: server_error"],
	["has no code", "&client_id=oaiapp_9", "The ChatGPT sign-in's callback has no code"],
	["has no issued client ID", "&code=code-1", "The ChatGPT sign-in's callback has no issued client ID, so it didn't finish. Sign in again"],
	["keeps the shared client ID", "&code=code-1&client_id=dynamic_agent_client", "The ChatGPT sign-in's callback has no issued client ID, so it didn't finish. Sign in again"],
])("fails and saves no tokens when the callback %s", async (_name, extra, error) => {
	const { io, seen } = setUp({ visit: (authorize) => [callbackQuery(authorize, extra)] });

	expect(await run(io, seen)).toEqual({ ok: false, error });
	expect(readAuth()).not.toHaveProperty("tokens");
	expect(seen.pages[0].text).toBe(error.startsWith("The ChatGPT sign-in's callback has no issued") ? "Signed in. You can close this tab and go back to the bridge." : `${error}. You can close this tab.`);
});

test.each([
	["the code exchange is refused", () => json({ error: "invalid_grant" }, 400), "OpenAI refused the ChatGPT token request with 400: invalid_grant"],
	["the reply has no refresh token", () => json({ access_token: "a", id_token: "i", expires_in: 1, scope: PLAN_SCOPES }), "The ChatGPT sign-in's reply has no refresh token or ID token"],
	["the plan scope isn't granted", () => json({ access_token: "a", refresh_token: "r", id_token: "i", expires_in: 1, scope: "openid" }), "The ChatGPT sign-in didn't grant chatgpt.tokens.use.direct, which plan usage needs"],
	["the ID token is for another sign-in", () => goodReply("nonce-other"), "The ChatGPT sign-in's ID token is for another sign-in"],
])("fails and saves no tokens when %s", async (_name, tokenReply, error) => {
	const { io, seen } = setUp({ tokenReply });

	expect(await run(io, seen)).toEqual({ ok: false, error });
	expect(readAuth()).not.toHaveProperty("tokens");
});

test("fails when OpenAI's keys can't be read", async () => {
	const { io, seen } = setUp({ keys: json({}, 500) });

	expect(await run(io, seen)).toEqual({ ok: false, error: `Couldn't get OpenAI's keys to check the ChatGPT sign-in: ${JWKS_URL} answered with 500` });
});

test("fails when the browser never comes back", async () => {
	const { io, seen } = setUp({ visit: () => [], timeoutMs: 20 });

	expect(await run(io, seen)).toEqual({ ok: false, error: "The ChatGPT sign-in timed out" });
});

test("ignores a callback for another attempt", () => {
	expect(readCallback(new URLSearchParams("code=x"), "state-1")).toBeUndefined();
});
