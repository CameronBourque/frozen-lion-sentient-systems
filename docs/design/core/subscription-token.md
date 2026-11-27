# Subscription token

How agents play on a user's paid plan with a token from the provider's browser sign-in, through the bridge's own agent loop. OpenAI's ChatGPT plan is the one provider. Part of [run modes](run-modes.md).

The bridge's loop and the [model client](model-client.md) stay the same. The provider model gets a token in place of an API key, and the model client streams the call.

- **Sign-in.** `signIn` in `src/model/sign-in/openai.ts` uses the saved token when it works or refreshes. A refresh that fails with the tokens kept, such as with no network, fails the sign-in too, since the browser can't do better.

  Otherwise it opens the default browser to OpenAI's OAuth page with PKCE, logs the URL in case no browser opens, and listens on `127.0.0.1` on a free port for the callback.

  A request with another attempt's `state` gets a 404, and the bridge keeps waiting. After five minutes the sign-in fails. The menu row reads "Continue with ChatGPT".

  The first sign-in makes and saves the host ID, an `ext_agent_host_id` of `urn:uuid:` and a random UUID.

  It registers the bridge with `dynamic_agent_client` and `agent_name_hint` set to `Sentient Systems`, and saves the issued `client_id` from the callback, which every later sign-in and refresh uses.

  A later sign-in sends the last ID token as `id_token_hint`. The bridge checks that the granted scopes include `chatgpt.tokens.use.direct`.

  It also checks the ID token in `src/model/sign-in/id-token.ts` against the keys at the `jwks_uri` in OpenAI's OpenID configuration. A failed check saves no tokens.
- **Tokens.** `src/model/sign-in/openai-tokens.ts` keeps them. `auth/openai.json` in the config file's folder holds the client ID, the host ID, the last ID token, and the tokens. The config file never does, because users may share it, and the refresh token changes on every refresh.

  The ID token stays when a spent refresh clears the tokens, so the next sign-in can still send it.

  The terminal bridge saves the tokens with no question. A GUI will ask the user to opt in to saving them, and without it the user signs in on each start.
- **Refresh.** Before each request, the bridge checks the access token's expiry. With less than a minute left, it refreshes the token first. A request that comes during a refresh waits for that refresh, so only one runs at a time.

  A request refused with 401 refreshes once and tries again, unless another request already replaced that token. A refresh refused as spent, such as `invalid_grant`, clears the tokens, and `invalid_client` clears the client ID too. The picker then asks to sign in again on the next start.

  A refresh that fails for any other reason keeps the tokens, so a network outage doesn't sign the user out. The file is written to a temporary file and renamed, so a crash mid-write can't lose the refresh token.
- **Calls.** `subscriptionMode` in `src/model/providers/openai.ts` builds the mode from `subscriptionCredential`, whose source is the token store and which is ready once signed in. Its model's API key is a function that the SDK calls before each request, which returns the store's current token.

  The model's `fetch` handles a 401: it refreshes once and sends again with the new token. A token that can't refresh fails the call with the refresh's reason and sends nothing.

  The model's base URL is fixed to `https://api.openai.com/v1`, so an `OPENAI_BASE_URL` set for the API key mode can't send the plan's token to another server.

  A middleware sends each call to the Responses API with `store: false` and moves the system prompt from the messages to `instructions`. It also marks a usage limit as not to retry, since every retry fails until the plan resets. Each call streams, with none of the fields the plan rejects.
- **Model list.** The picker lists the models right after `signIn`, so the list's request uses that token.

  `SUBSCRIPTION_LISTER` in `src/model/providers/openai.ts` reads `/v1/models`, which has its own reply shape on a plan. It keeps the entries whose `visibility` is `list`, in OpenAI's order, with `display_name` as the name.
- **First use.** After each sign-in through the browser, the bridge logs "You're using your ChatGPT plan", with the usage page.
- **Failures.** Each of the plan's error codes is its own [failure kind](model-client.md#failures). A 401 or 403 with none of these codes is `auth`, and its message says to sign in again.

  - `limit`, for `subscription_sharing_usage_limit_exceeded`. Its message gives `https://chatgpt.com/settings/usage`, and the agent loop stops the run as a run spending limit does.
  - `not-eligible`, for `subscription_sharing_user_not_eligible`. Its message says the account's plan can't be used by other apps, and the agent loop stops the turn.
  - `unavailable`, for `subscription_sharing_usage_unavailable`. The SDK retries it as a server error, and the agent loop treats it as `other`.
  - `unsupported`, for `subscription_sharing_unsupported_capability`. The bridge sent a field the plan rejects, which is a bridge bug, so its message asks the user to report it. The agent loop stops the turn.
- **Price.** A plan has no price per token, so the model menu shows none and `model.price` stays blank. The log shows tokens with no cost, and only the token [spending limits](../agents/turn-loop/stopping.md) apply.

[findings/plan-access/openai.md](../../findings/plan-access/openai.md) has OpenAI's URLs, fields, and error codes.

## Decisions

| Decision | Reason |
| --- | --- |
| The access token refreshes only when less than a minute is left | Each refresh replaces the refresh token. A refresh on every request adds a round trip and more chances of `refresh_token_reused` |
| The plan model's API key is a function that returns the current token | The picker builds the model once, and a game lasts longer than the hour a token lasts. A fixed placeholder key would need a `fetch` to replace it on every request |
| The plan model's base URL is fixed | The SDK reads `OPENAI_BASE_URL`, which a user may set for a proxy in the API key mode. The plan's token is for OpenAI only |
| The system prompt goes in `instructions`, not a `developer` message | Both have the same authority, and OpenAI's own clients use `instructions`. It always comes first, apart from the messages the bridge may trim |
| The plan's request rules live in a middleware on the model | `callModel` stays the same in every run mode, and OpenAI's plan rules stay in OpenAI's file |
| The sign-in code is OpenAI's own until a second plan provider exists | [Plan access](../../findings/plan-access/README.md) finds no second provider, and OpenAI's flow is unusual. A second one moves the callback server and PKCE to a shared file, and OpenAI's URLs, scopes, and refresh codes to a description object, like a lister |
| The browser opens with `rundll32 url.dll,FileProtocolHandler` on Windows | `start` runs through `cmd`, which reads each `&` in the sign-in URL as a new command |
| The ID token check uses `node:crypto`, with no JWT package | The check is one RS256 signature and four claims, and Node reads a JWK |
| Plan tokens live in `auth/`, not the config file | Users may share the config file. The refresh token changes on each refresh, and rewriting the config file each hour would risk the user's edits |
| Only a GUI asks before saving plan tokens | A terminal user runs the bridge on their own computer, and a question on every start adds a step. A GUI has room for the setting, and a user on a shared computer may not want a sign-in kept on disk |
| A usage limit stops the run as a run spending limit does | Every later call fails until the plan resets, and the bridge can't tell when that is. Forced end turns would play turn after turn with no model. A stopped run resumes the same turn on the next start |
