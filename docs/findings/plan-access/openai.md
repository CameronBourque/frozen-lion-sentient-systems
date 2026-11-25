# OpenAI plan access

Status: confirmed. A live call on a ChatGPT Plus plan on 2026-11-25 confirmed the sign-in, the call, and the token reply. The rest is from OpenAI's docs, read on 2026-11-22 and 2026-11-23.

How an open-source app signs in to a user's ChatGPT plan and calls OpenAI's API with its token. Part of [plan access](README.md).

## Questions

1. Does a plan reply report cached tokens? The live call's prompt was too short to cache.

## What we know now

- **ChatGPT plan usage.** An open-source app that runs on the user's computer may send requests on the user's ChatGPT plan. The overview says it is "for open-source and locally hosted apps". Paid or hosted apps use an interest form instead. Source: [token-sharing-open-source](https://developers.openai.com/siwc/token-sharing-open-source).
- **Registration.** None ahead of time. The first sign-in passes `client_id=dynamic_agent_client`, `ext_agent_host_id`, and `agent_name_hint`, and the callback returns an issued `client_id` to save and reuse. No client secret or partner key. Source: [sign-in](https://developers.openai.com/siwc/token-sharing-open-source/sign-in).
- **Issued client ID.** It starts with `oaiapp_` and comes back in the callback's query, not in the token response. A first sign-in whose callback has no issued ID is incomplete. Never save `dynamic_agent_client` as the issued ID.
- **Host ID.** `ext_agent_host_id` is made once for each computer and saved before the first sign-in. It is opaque and never names the user. The overview allows a JWK thumbprint URN, a `did:key`, or `urn:uuid:` followed by a UUID v4.
- **What counts as open source.** The docs don't define it or name a license.
- **Sign-in.** Browser OAuth with PKCE `S256`. No device code flow. The browser opens `https://auth.openai.com/api/accounts/authorize` with these query parameters:
  - `client_id`, `response_type=code`, `redirect_uri`, `scope`, `resource=https://api.openai.com/v1`, `state`, `nonce`, `code_challenge_method=S256`, and `code_challenge`,
  - `ext_agent_host_id`, and `agent_name_hint` on the first sign-in only,
  - optionally, `id_token_hint` from the last sign-in and `login_hint` with an email.
- **Redirect.** `http://127.0.0.1:<port>/auth/callback`, never `localhost`, and only the port may change. Each attempt gets a new `state`, `nonce`, and PKCE pair.

  The callback has `code`, `state`, and, on the first sign-in, the issued `client_id`. Check `state` before anything else. On `error=access_denied`, stop with no code exchange.
- **Returning sign-in.** With the issued `client_id`, the same host ID, and the last `id_token` as `id_token_hint`, OpenAI skips account choice and consent. Source: [profiles-and-sessions](https://developers.openai.com/siwc/token-sharing-open-source/profiles-and-sessions).
- **Code exchange.** A form-encoded `POST https://auth.openai.com/api/accounts/oauth/token` with `grant_type=authorization_code`, `client_id`, `code`, `code_verifier`, the same `redirect_uri`, and the same `resource`. On `invalid_grant`, sign in again.
- **ID token.** Check its signature against OpenAI's JWKS, and its issuer, audience, expiry, and nonce. The audience is the issued client ID.
- **Scopes.** `openid profile email offline_access resource.invoke chatgpt.tokens.use.direct`. Plan usage needs `chatgpt.tokens.use.direct` in the granted scopes.
- **Token response.** `access_token`, `refresh_token`, `id_token`, `token_type`, `expires_in`, `scope`, and `earliest_refresh_at`. The `refresh_token` comes only with `offline_access`. Source: [token-reference](https://developers.openai.com/siwc/token-sharing-open-source/token-reference).
- **Tokens.** The access token lasts 1 hour. The refresh token lasts 30 days, and each refresh returns a new one with a new 30 days. Refreshes must not run at the same time.
- **Refresh.** The same token URL, form-encoded, with `grant_type=refresh_token`, the issued `client_id`, `refresh_token`, and `resource`, and no `scope`. Source: [profiles-and-sessions](https://developers.openai.com/siwc/token-sharing-open-source/profiles-and-sessions).

  These errors mean clear the tokens and sign in again: `invalid_grant`, `invalid_refresh_token`, `token_expired`, `refresh_token_expired`, `refresh_token_invalidated`, and `refresh_token_reused`. `invalid_client` means the client ID is wrong.
- **Revoke.** A form-encoded `POST` to the `revocation_endpoint` in `https://auth.openai.com/.well-known/openid-configuration`, with `token`, `token_type_hint=refresh_token`, and the issued `client_id`. Revoking keeps the registered client.
- **Calls.** `POST https://api.openai.com/v1/responses` with the token as `Authorization: Bearer`. Every request sets `store: false` and `stream: true`, and `input` is an array with the whole history. A reply counts only after `response.completed`. Source: [models-and-inference](https://developers.openai.com/siwc/token-sharing-open-source/models-and-inference).
- **Rejected fields.** `background`, `conversation`, `max_output_tokens`, `max_tool_calls`, `metadata`, `moderation`, `multi_agent`, `prompt`, `prompt_cache_retention`, `safety_identifier`, `temperature`, `top_logprobs`, `top_p`, `truncation`, `user`, and `previous_response_id`.

  A `system` role message is rejected. The system prompt goes in `instructions` or a `developer` message. The page doesn't mention `include`, `reasoning`, `tool_choice`, or `parallel_tool_calls`. Source: [preview-limitations](https://developers.openai.com/siwc/token-sharing-open-source/preview-limitations).
- **Tools.** Function and custom tools work. Image generation, file search, Code Interpreter, computer use, hosted MCP, and tool search don't.
- **Models.** `GET https://api.openai.com/v1/models` with the token. The reply is a `models` array, and each entry has `slug`, `display_name`, and `visibility`. Keep each entry whose `visibility` is `list`. The page names no other field or value.
- **Plans and limits.** The docs don't list which plans are eligible. They name Plus and Pro: a Plus plan's five-hour limit is shared by every app that uses the plan, and Pro has no five-hour limit. Source: [profiles-and-sessions](https://developers.openai.com/siwc/token-sharing-open-source/profiles-and-sessions).
- **Errors.** `subscription_sharing_usage_limit_exceeded` (429), `subscription_sharing_usage_unavailable` (503), `subscription_sharing_user_not_eligible` (403), and `subscription_sharing_unsupported_capability` (400).

  A limit can arrive mid-stream as `response.failed`. The docs say not to guess a reset time from the code. Source: [errors-and-recovery](https://developers.openai.com/siwc/token-sharing-open-source/errors-and-recovery).
- **Wording.** The sign-in action reads "Continue with ChatGPT". The first sign-in shows "You're using your ChatGPT plan", and a usage limit links to `https://chatgpt.com/settings/usage`. Source: [ui-ux-guidelines](https://developers.openai.com/siwc/ui-ux-guidelines).
- **Codex SDK.** `@openai/codex-sdk` spawns the `codex` CLI and streams its events. Its docs show no way to abort a run. Source: [codex-sdk](https://learn.chatgpt.com/docs/codex-sdk).

## Method

1. To answer question 1, run the bridge's agent loop on a plan for a few turns, and check the `model_call` records for nonzero cache reads.

The live check signed in with a ChatGPT Plus plan, ran `npm run ask` with a reasoning model, and read the `model_call` record and `auth/openai.json`.

## Results

On a ChatGPT Plus trial with `gpt-6.2-sol` at medium effort:

- **Tokens.** The reply reports input and output tokens: 85 and 20.
- **Request shape.** The AI SDK's call, with `store: false`, streaming, and the system prompt in `instructions`, came back with a tool call.
- **Reasoning.** The plan accepts `include: ["reasoning.encrypted_content"]`, which the AI SDK adds to a reasoning model's call.
- **`earliest_refresh_at`.** A Unix time in seconds, 6 minutes before the access token expires.
- **No plan.** An account with no plan got through the browser sign-in, then the code exchange failed with `invalid_grant`, not `subscription_sharing_user_not_eligible`.
- **Usage cap.** ChatGPT's settings let the user cap how much of the plan each app may use.

Date checked: 2026-11-25.
