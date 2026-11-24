// Keeps the ChatGPT plan's tokens in auth/openai.json beside the config file,
// and refreshes the access token before it runs out.
// docs/design/core/subscription-token.md has the design.

import fs from "node:fs";
import path from "node:path";
import { z } from "zod";
import type { Logger } from "../../log.js";
import type { SecretResult } from "../providers/mode.js";

export const TOKEN_URL = "https://auth.openai.com/api/accounts/oauth/token";
export const RESOURCE = "https://api.openai.com/v1";

const SCHEMA_VERSION = 1;
const REFRESH_MARGIN_MS = 60_000;
const NOT_SIGNED_IN = "Not signed in to a ChatGPT plan";

// OpenAI's refresh errors that mean the refresh token is spent.
const SIGN_IN_AGAIN = new Set(["invalid_grant", "invalid_refresh_token", "token_expired", "refresh_token_expired", "refresh_token_invalidated", "refresh_token_reused"]);

const TOKENS = z.strictObject({
	access: z.string(),
	refresh: z.string(),
	id: z.string(),
	expiresAt: z.number().describe("When the access token runs out, in milliseconds since 1970"),
	scopes: z.array(z.string()),
	earliestRefreshAt: z.unknown().optional().describe("Kept from the token reply until the live check says what it means"),
});

const AUTH_FILE = z.strictObject({
	schemaVersion: z.literal(SCHEMA_VERSION),
	hostId: z.string(),
	clientId: z.string().optional(),
	tokens: TOKENS.optional(),
});

const TOKEN_REPLY = z.object({
	access_token: z.string(),
	refresh_token: z.string().optional(),
	id_token: z.string().optional(),
	expires_in: z.number(),
	scope: z.string().optional(),
	earliest_refresh_at: z.unknown().optional(),
});

const ERROR_REPLY = z.object({ error: z.string() });

type Tokens = z.infer<typeof TOKENS>;
type AuthFile = z.infer<typeof AUTH_FILE>;
export type TokenReply = z.infer<typeof TOKEN_REPLY>;

export type TokenResult =
	| { ok: true; reply: TokenReply }
	| { ok: false; error: string; code?: string };

export type Post = (url: string, init: { method: "POST"; headers: Record<string, string>; body: string }) => Promise<Response>;

export interface TokenIo {
	post: Post;
	now: () => number;
	log: Pick<Logger, "info" | "warn">;
}

export interface OpenAITokens {
	signedIn: () => boolean;
	// A token with at least a minute left, refreshed first when needed.
	secret: () => Promise<SecretResult>;
	// After a request with this token got 401. Another request may have
	// refreshed it already.
	refreshAfterRefusal: (rejected: string) => Promise<SecretResult>;
}

export function authFilePath(folder: string): string {
	return path.join(folder, "auth", "openai.json");
}

// Sends a form to the token URL, for a code exchange or a refresh.
export async function requestTokens(form: Record<string, string>, post: Post): Promise<TokenResult> {
	try {
		const response = await post(TOKEN_URL, {
			method: "POST",
			headers: { "Content-Type": "application/x-www-form-urlencoded" },
			body: new URLSearchParams(form).toString(),
		});
		const body: unknown = await response.json().catch(() => undefined);

		if (!response.ok) {
			const code = ERROR_REPLY.safeParse(body).data?.error;

			return { ok: false, error: `OpenAI refused the ChatGPT token request with ${response.status}${code === undefined ? "" : `: ${code}`}`, code };
		}

		return { ok: true, reply: TOKEN_REPLY.parse(body) };
	} catch (error) {
		// fetch and zod throw only errors.
		return { ok: false, error: `Couldn't get a ChatGPT token: ${(error as Error).message}` };
	}
}

// A refresh may leave out the refresh token, the ID token, or the scopes, which
// then stay as they were.
function refreshedTokens(reply: TokenReply, previous: Tokens, now: number): Tokens {
	return {
		access: reply.access_token,
		refresh: reply.refresh_token ?? previous.refresh,
		id: reply.id_token ?? previous.id,
		expiresAt: now + reply.expires_in * 1000,
		scopes: reply.scope?.split(" ") ?? previous.scopes,
		earliestRefreshAt: reply.earliest_refresh_at,
	};
}

export function openAITokens(folder: string, io: TokenIo): OpenAITokens {
	const file = authFilePath(folder);
	let auth: AuthFile | undefined;
	let loaded = false;
	let refreshing: Promise<SecretResult> | undefined;

	// A missing file means signed out. A file that can't be read is the same,
	// with a warning, and the next sign-in replaces it.
	function load(): AuthFile | undefined {
		if (!loaded) {
			loaded = true;

			if (fs.existsSync(file)) {
				try {
					auth = AUTH_FILE.parse(JSON.parse(fs.readFileSync(file, "utf8")));
				} catch (error) {
					io.log.warn("auth_file_unreadable", `Couldn't read ${file}, so the ChatGPT plan is signed out: ${(error as Error).message}`, { path: file });
				}
			}
		}

		return auth;
	}

	// Writes a temporary file first, so a crash mid-write can't lose the
	// refresh token. A failed write keeps the tokens in memory for this run.
	function save(next: AuthFile): void {
		auth = next;

		try {
			fs.mkdirSync(path.dirname(file), { recursive: true });
			fs.writeFileSync(`${file}.tmp`, JSON.stringify(next, null, "\t"), { mode: 0o600 });
			fs.renameSync(`${file}.tmp`, file);
		} catch (error) {
			io.log.warn("auth_file_unsaved", `Couldn't save ${file}, so the next start may ask to sign in again: ${(error as Error).message}`, { path: file });
		}
	}

	async function refresh(current: AuthFile, clientId: string, tokens: Tokens): Promise<SecretResult> {
		const result = await requestTokens({ grant_type: "refresh_token", client_id: clientId, refresh_token: tokens.refresh, resource: RESOURCE }, io.post);

		if (!result.ok) {
			if (result.code === "invalid_client") {
				save({ ...current, clientId: undefined, tokens: undefined });
			} else if (result.code !== undefined && SIGN_IN_AGAIN.has(result.code)) {
				save({ ...current, tokens: undefined });
			}

			return { ok: false, error: result.error };
		}

		const next = refreshedTokens(result.reply, tokens, io.now());

		save({ ...current, tokens: next });
		io.log.info("chatgpt_token_refreshed", `Refreshed the ChatGPT token, which lasts ${result.reply.expires_in} seconds`, { expiresIn: result.reply.expires_in, earliestRefreshAt: next.earliestRefreshAt });

		return { ok: true, secret: next.access };
	}

	// Starts a refresh, or joins the one already running, so two never run at
	// once.
	function refreshOnce(): Promise<SecretResult> {
		const current = load();

		if (current?.clientId === undefined || current.tokens === undefined) {
			return Promise.resolve({ ok: false, error: NOT_SIGNED_IN });
		}

		refreshing ??= refresh(current, current.clientId, current.tokens).finally(() => {
			refreshing = undefined;
		});

		return refreshing;
	}

	// Waits for a refresh that is running, or passes the token to check.
	function settled(check: (tokens: Tokens) => boolean): Promise<SecretResult> {
		if (refreshing !== undefined) {
			return refreshing;
		}

		const tokens = load()?.tokens;

		return tokens !== undefined && check(tokens) ? Promise.resolve({ ok: true, secret: tokens.access }) : refreshOnce();
	}

	return {
		signedIn: () => load()?.tokens !== undefined,
		secret: () => settled((tokens) => tokens.expiresAt - io.now() > REFRESH_MARGIN_MS),
		refreshAfterRefusal: (rejected) => settled((tokens) => tokens.access !== rejected),
	};
}
