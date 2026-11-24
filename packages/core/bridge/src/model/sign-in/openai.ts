// Signs in to a ChatGPT plan through the browser, with PKCE and a callback on
// 127.0.0.1, or uses the saved token when it still works.
// docs/design/core/subscription-token.md has the design.

import crypto from "node:crypto";
import http from "node:http";
import { z } from "zod";
import type { SecretResult } from "../providers/mode.js";
import { JWKS, checkIdToken } from "./id-token.js";
import { type OpenAITokens, RESOURCE, type SignInHints, type SignedInReply, type TokenIo, requestTokens } from "./openai-tokens.js";

export const AUTHORIZE_URL = "https://auth.openai.com/api/accounts/authorize";
export const DISCOVERY_URL = "https://auth.openai.com/.well-known/openid-configuration";

const SCOPES = "openid profile email offline_access resource.invoke chatgpt.tokens.use.direct";
const PLAN_SCOPE = "chatgpt.tokens.use.direct";
const FIRST_CLIENT_ID = "dynamic_agent_client";
const ISSUED_CLIENT_PREFIX = "oaiapp_";
const AGENT_NAME = "Sentient Systems";
const CALLBACK_PATH = "/auth/callback";
const SIGN_IN_TIMEOUT_MS = 5 * 60_000;

const DISCOVERY = z.object({ issuer: z.string(), jwks_uri: z.string() });

export interface SignInIo extends TokenIo {
	get: (url: string) => Promise<Response>;
	openBrowser: (url: string) => void;
	timeoutMs?: number;
}

type Callback =
	| { ok: true; code: string; issuedClientId?: string }
	| { ok: false; error: string };

interface Listening {
	redirectUri: string;
	callback: Promise<Callback>;
}

// What one sign-in attempt sends, made new for each attempt.
interface Attempt {
	verifier: string;
	state: string;
	nonce: string;
}

function randomText(): string {
	return crypto.randomBytes(32).toString("base64url");
}

export function authorizeUrl(hints: SignInHints, attempt: Attempt, redirectUri: string): string {
	const url = new URL(AUTHORIZE_URL);
	const params: Record<string, string | undefined> = {
		client_id: hints.clientId ?? FIRST_CLIENT_ID,
		response_type: "code",
		redirect_uri: redirectUri,
		scope: SCOPES,
		resource: RESOURCE,
		state: attempt.state,
		nonce: attempt.nonce,
		code_challenge_method: "S256",
		code_challenge: crypto.createHash("sha256").update(attempt.verifier).digest("base64url"),
		ext_agent_host_id: hints.hostId,
		// Only the first sign-in registers the bridge under a name.
		agent_name_hint: hints.clientId === undefined ? AGENT_NAME : undefined,
		id_token_hint: hints.idToken,
	};

	Object.entries(params).forEach(([name, value]) => {
		if (value !== undefined) {
			url.searchParams.set(name, value);
		}
	});

	return url.toString();
}

// Reads the callback's query. The state comes first, so a stray or old link
// changes nothing, and the caller keeps waiting.
export function readCallback(query: URLSearchParams, state: string): Callback | undefined {
	if (query.get("state") !== state) {
		return undefined;
	}

	const error = query.get("error");

	if (error !== null) {
		return { ok: false, error: error === "access_denied" ? "The ChatGPT sign-in was cancelled" : `The ChatGPT sign-in failed: ${error}` };
	}

	const code = query.get("code");

	return code === null ? { ok: false, error: "The ChatGPT sign-in's callback has no code" } : { ok: true, code, issuedClientId: query.get("client_id") ?? undefined };
}

// Listens on a free port until the browser comes back with this attempt's
// state, or the time runs out.
function listenForCallback(state: string, timeoutMs: number): Promise<Listening> {
	return new Promise((resolve, reject) => {
		let finish: (callback: Callback) => void = () => undefined;
		const callback = new Promise<Callback>((settle) => {
			finish = settle;
		});
		const server = http.createServer((request, response) => {
			const url = new URL(request.url ?? "/", "http://127.0.0.1");
			const read = url.pathname === CALLBACK_PATH ? readCallback(url.searchParams, state) : undefined;

			response.writeHead(read === undefined ? 404 : 200, { "Content-Type": "text/plain; charset=utf-8", Connection: "close" });

			if (read === undefined) {
				response.end("This isn't the current sign-in.");

				return;
			}

			response.end(read.ok ? "Signed in. You can close this tab and go back to the bridge." : `${read.error}. You can close this tab.`);
			finish(read);
		});
		const timer = setTimeout(() => finish({ ok: false, error: "The ChatGPT sign-in timed out" }), timeoutMs);

		void callback.then(() => {
			clearTimeout(timer);
			server.close();
			server.closeAllConnections();
		});
		server.once("error", reject);
		server.listen(0, "127.0.0.1", () => {
			resolve({ redirectUri: `http://127.0.0.1:${(server.address() as { port: number }).port}${CALLBACK_PATH}`, callback });
		});
	});
}

async function getJson(url: string, io: SignInIo): Promise<unknown> {
	const response = await io.get(url);

	if (!response.ok) {
		throw new Error(`${url} answered with ${response.status}`);
	}

	return response.json();
}

async function checkReply(reply: SignedInReply, clientId: string, nonce: string, io: SignInIo): Promise<string | undefined> {
	if (!reply.scope?.split(" ").includes(PLAN_SCOPE)) {
		return `The ChatGPT sign-in didn't grant ${PLAN_SCOPE}, which plan usage needs`;
	}

	try {
		const discovery = DISCOVERY.parse(await getJson(DISCOVERY_URL, io));
		const { keys } = JWKS.parse(await getJson(discovery.jwks_uri, io));
		const checked = checkIdToken(reply.id_token, keys, { issuer: discovery.issuer, audience: clientId, nonce, now: io.now() });

		return checked.ok ? undefined : checked.error;
	} catch (error) {
		// fetch and zod throw only errors.
		return `Couldn't get OpenAI's keys to check the ChatGPT sign-in: ${(error as Error).message}`;
	}
}

// Trades the callback's code for tokens, checks them, and saves them.
async function finishSignIn(tokens: OpenAITokens, hints: SignInHints, callback: Callback, attempt: Attempt, redirectUri: string, io: SignInIo): Promise<SecretResult> {
	if (!callback.ok) {
		return callback;
	}

	// The first sign-in gets its client ID in the callback, and must never
	// keep the shared one.
	const clientId = hints.clientId ?? callback.issuedClientId;

	if (clientId?.startsWith(ISSUED_CLIENT_PREFIX) !== true) {
		return { ok: false, error: "The ChatGPT sign-in's callback has no issued client ID, so it didn't finish. Sign in again" };
	}

	const exchanged = await requestTokens({ grant_type: "authorization_code", client_id: clientId, code: callback.code, code_verifier: attempt.verifier, redirect_uri: redirectUri, resource: RESOURCE }, io.post);

	if (!exchanged.ok) {
		return { ok: false, error: exchanged.error };
	}

	const { reply } = exchanged;

	if (reply.refresh_token === undefined || reply.id_token === undefined) {
		return { ok: false, error: "The ChatGPT sign-in's reply has no refresh token or ID token" };
	}

	const signedIn = { ...reply, refresh_token: reply.refresh_token, id_token: reply.id_token };
	const problem = await checkReply(signedIn, clientId, attempt.nonce, io);

	return problem === undefined ? { ok: true, secret: tokens.saveSignIn(clientId, signedIn) } : { ok: false, error: problem };
}

async function browserSignIn(tokens: OpenAITokens, io: SignInIo): Promise<SecretResult> {
	const hints = tokens.signInHints();
	const attempt = { verifier: randomText(), state: randomText(), nonce: randomText() };
	let listening: Listening;

	try {
		listening = await listenForCallback(attempt.state, io.timeoutMs ?? SIGN_IN_TIMEOUT_MS);
	} catch (error) {
		// node:http's errors are Errors.
		return { ok: false, error: `Couldn't listen for the ChatGPT sign-in: ${(error as Error).message}` };
	}

	const url = authorizeUrl(hints, attempt, listening.redirectUri);

	io.log.info("chatgpt_sign_in", `Continue with ChatGPT in your browser. If it doesn't open, go to ${url}`);
	io.openBrowser(url);

	return finishSignIn(tokens, hints, await listening.callback, attempt, listening.redirectUri, io);
}

// The saved token when it works or refreshes. A refresh that fails with the
// tokens kept, such as with no network, fails here too, since the browser
// can't do better.
export async function signIn(tokens: OpenAITokens, io: SignInIo): Promise<SecretResult> {
	if (tokens.signedIn()) {
		const saved = await tokens.secret();

		if (saved.ok || tokens.signedIn()) {
			return saved;
		}
	}

	return browserSignIn(tokens, io);
}
