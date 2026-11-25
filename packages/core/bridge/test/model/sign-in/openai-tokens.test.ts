// Tests for model/sign-in/openai-tokens.ts: the saved token, its refresh, and
// what a refused or failed refresh leaves in auth/openai.json.

import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { afterEach, beforeEach, expect, test } from "vitest";
import { type Post, type TokenIo, TOKEN_URL, authFilePath, openAITokens } from "../../../src/model/sign-in/openai-tokens.js";

const NOW = 1_000_000;
const HOUR_MS = 3_600_000;

const SAVED = {
	schemaVersion: 1,
	hostId: "urn:uuid:00000000-0000-4000-8000-000000000000",
	clientId: "oaiapp_1",
	idToken: "id-1",
	tokens: { access: "access-1", refresh: "refresh-1", expiresAt: NOW + HOUR_MS, scopes: ["openid", "chatgpt.tokens.use.direct"] },
};

const REFRESHED = { access_token: "access-2", refresh_token: "refresh-2", id_token: "id-2", expires_in: 3600, scope: "openid chatgpt.tokens.use.direct", earliest_refresh_at: 1234 };

interface Logged {
	level: "info" | "warn";
	event: string;
}

let folder: string;

beforeEach(() => {
	folder = fs.mkdtempSync(path.join(os.tmpdir(), "sentient-systems-"));
});

afterEach(() => {
	fs.rmSync(folder, { recursive: true, force: true });
});

function writeAuth(auth: unknown): void {
	fs.mkdirSync(path.join(folder, "auth"));
	fs.writeFileSync(authFilePath(folder), typeof auth === "string" ? auth : JSON.stringify(auth));
}

function readAuth(): unknown {
	return JSON.parse(fs.readFileSync(authFilePath(folder), "utf8"));
}

function expiring(): typeof SAVED {
	return { ...SAVED, tokens: { ...SAVED.tokens, expiresAt: NOW + 30_000 } };
}

// Answers each request with the next reply, and records the forms it got.
// A reply that is a promise lets a test hold the request open.
function fakePost(replies: (Response | Promise<Response>)[], forms: Record<string, string>[]): Post {
	return (url, init) => {
		expect(url).toBe(TOKEN_URL);
		expect(init.headers).toEqual({ "Content-Type": "application/x-www-form-urlencoded" });
		forms.push(Object.fromEntries(new URLSearchParams(init.body)));

		return Promise.resolve(replies.shift() ?? new Response("", { status: 500 }));
	};
}

function json(body: unknown, status = 200): Response {
	return new Response(JSON.stringify(body), { status });
}

function ioWith(post: Post, logged: Logged[] = []): TokenIo {
	return {
		post,
		now: () => NOW,
		log: {
			info: (event) => logged.push({ level: "info", event }),
			warn: (event) => logged.push({ level: "warn", event }),
		},
	};
}

test("gives the saved token while more than a minute is left, with no request", async () => {
	const forms: Record<string, string>[] = [];

	writeAuth(SAVED);
	const tokens = openAITokens(folder, ioWith(fakePost([], forms)));

	expect(tokens.signedIn()).toBe(true);
	expect(await tokens.secret()).toEqual({ ok: true, secret: "access-1" });
	expect(forms).toEqual([]);
});

test("refreshes with less than a minute left, and saves the new tokens", async () => {
	const forms: Record<string, string>[] = [];
	const logged: Logged[] = [];

	writeAuth(expiring());
	const tokens = openAITokens(folder, ioWith(fakePost([json(REFRESHED)], forms), logged));

	expect(await tokens.secret()).toEqual({ ok: true, secret: "access-2" });
	expect(forms).toEqual([{ grant_type: "refresh_token", client_id: "oaiapp_1", refresh_token: "refresh-1", resource: "https://api.openai.com/v1" }]);
	expect(readAuth()).toEqual({
		...SAVED,
		idToken: "id-2",
		tokens: { access: "access-2", refresh: "refresh-2", expiresAt: NOW + HOUR_MS, scopes: ["openid", "chatgpt.tokens.use.direct"], earliestRefreshAt: 1234 },
	});
	expect(logged).toEqual([{ level: "info", event: "chatgpt_token_refreshed" }]);
	expect(await tokens.secret()).toEqual({ ok: true, secret: "access-2" });
	expect(forms).toHaveLength(1);
});

test("keeps the refresh token, the ID token, and the scopes a refresh leaves out", async () => {
	writeAuth(expiring());
	const tokens = openAITokens(folder, ioWith(fakePost([json({ access_token: "access-2", expires_in: 60 })], [])));

	expect(await tokens.secret()).toEqual({ ok: true, secret: "access-2" });
	expect(readAuth()).toEqual({ ...SAVED, tokens: { ...SAVED.tokens, access: "access-2", expiresAt: NOW + 60_000 } });
});

test("runs one refresh for two requests at once", async () => {
	const forms: Record<string, string>[] = [];
	let answer: (response: Response) => void = () => undefined;

	writeAuth(expiring());
	const tokens = openAITokens(folder, ioWith(fakePost([new Promise((resolve) => {
		answer = resolve;
	})], forms)));
	const first = tokens.secret();
	const second = tokens.secret();

	answer(json(REFRESHED));
	expect(await Promise.all([first, second])).toEqual([{ ok: true, secret: "access-2" }, { ok: true, secret: "access-2" }]);
	expect(forms).toHaveLength(1);
});

test.each(["invalid_grant", "refresh_token_reused"])("clears the tokens on %s, and keeps the client", async (code) => {
	writeAuth(expiring());
	const tokens = openAITokens(folder, ioWith(fakePost([json({ error: code }, 400)], [])));

	expect(await tokens.secret()).toEqual({ ok: false, error: `OpenAI refused the ChatGPT token request with 400: ${code}` });
	expect(readAuth()).toEqual({ schemaVersion: 1, hostId: SAVED.hostId, clientId: "oaiapp_1", idToken: "id-1" });
	expect(tokens.signedIn()).toBe(false);
	expect(await tokens.secret()).toEqual({ ok: false, error: "Not signed in to a ChatGPT plan" });
});

test("clears the client and the tokens on invalid_client, and keeps the host ID and the ID token", async () => {
	writeAuth(expiring());
	const tokens = openAITokens(folder, ioWith(fakePost([json({ error: "invalid_client" }, 401)], [])));

	expect((await tokens.secret()).ok).toBe(false);
	expect(readAuth()).toEqual({ schemaVersion: 1, hostId: SAVED.hostId, idToken: "id-1" });
});

test.each([
	["an unknown error", json({ error: "server_busy" }, 400), "OpenAI refused the ChatGPT token request with 400: server_busy"],
	["a reply with no error code", new Response("Bad gateway", { status: 502 }), "OpenAI refused the ChatGPT token request with 502"],
	["a reply in the wrong shape", json({ access_token: 1 }), expect.stringMatching(/^Couldn't get a ChatGPT token: /) as string],
])("keeps the tokens after %s", async (_name, reply, error) => {
	writeAuth(expiring());
	const tokens = openAITokens(folder, ioWith(fakePost([reply], [])));

	expect(await tokens.secret()).toEqual({ ok: false, error });
	expect(readAuth()).toEqual(expiring());
});

test("keeps the tokens when OpenAI can't be reached", async () => {
	writeAuth(expiring());
	const tokens = openAITokens(folder, ioWith(() => Promise.reject(new Error("offline"))));

	expect(await tokens.secret()).toEqual({ ok: false, error: "Couldn't get a ChatGPT token: offline" });
	expect(readAuth()).toEqual(expiring());
});

test("refreshes once after a 401 on the current token", async () => {
	const forms: Record<string, string>[] = [];

	writeAuth(SAVED);
	const tokens = openAITokens(folder, ioWith(fakePost([json(REFRESHED)], forms)));

	expect(await tokens.refreshAfterRefusal("access-1")).toEqual({ ok: true, secret: "access-2" });
	expect(await tokens.refreshAfterRefusal("access-1")).toEqual({ ok: true, secret: "access-2" });
	expect(forms).toHaveLength(1);
});

test("waits for a running refresh after a 401", async () => {
	const forms: Record<string, string>[] = [];
	let answer: (response: Response) => void = () => undefined;

	writeAuth(expiring());
	const tokens = openAITokens(folder, ioWith(fakePost([new Promise((resolve) => {
		answer = resolve;
	})], forms)));
	const refreshing = tokens.secret();
	const refused = tokens.refreshAfterRefusal("access-1");

	answer(json(REFRESHED));
	expect(await Promise.all([refreshing, refused])).toEqual([{ ok: true, secret: "access-2" }, { ok: true, secret: "access-2" }]);
	expect(forms).toHaveLength(1);
});

test("is signed out with no file", async () => {
	const tokens = openAITokens(folder, ioWith(fakePost([], [])));

	expect(tokens.signedIn()).toBe(false);
	expect(await tokens.refreshAfterRefusal("access-1")).toEqual({ ok: false, error: "Not signed in to a ChatGPT plan" });
});

test.each([
	["isn't JSON", "{"],
	["has the wrong shape", { ...SAVED, schemaVersion: 2 }],
])("warns and is signed out when the file %s", (_name, contents) => {
	const logged: Logged[] = [];

	writeAuth(contents);
	const tokens = openAITokens(folder, ioWith(fakePost([], []), logged));

	expect(tokens.signedIn()).toBe(false);
	expect(tokens.signedIn()).toBe(false);
	expect(logged).toEqual([{ level: "warn", event: "auth_file_unreadable" }]);
});

test("warns and keeps the new token for this run when the file can't be saved", async () => {
	const logged: Logged[] = [];

	writeAuth(expiring());
	// A folder where the temporary file goes makes the write fail.
	fs.mkdirSync(`${authFilePath(folder)}.tmp`);
	const tokens = openAITokens(folder, ioWith(fakePost([json(REFRESHED)], []), logged));

	expect(await tokens.secret()).toEqual({ ok: true, secret: "access-2" });
	expect(await tokens.secret()).toEqual({ ok: true, secret: "access-2" });
	expect(logged.map(({ event }) => event)).toEqual(["auth_file_unsaved", "chatgpt_token_refreshed"]);
});
