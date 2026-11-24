# Subscription token

How agents play on a user's paid plan with a token from the provider's browser sign-in, through the bridge's own agent loop. OpenAI's ChatGPT plan is the one provider. Part of [run modes](run-modes.md).

The bridge's loop and the [model client](model-client.md) stay the same. The provider model gets a token in place of an API key, and the model client streams the call.

- **Sign-in.** `signIn` in `src/model/sign-in/openai.ts` opens the browser to OpenAI's OAuth page with PKCE, and listens on `127.0.0.1` on a free port for the callback. The menu row reads "Continue with ChatGPT".

  The first sign-in registers the bridge with `dynamic_agent_client`, an `ext_agent_host_id` of `urn:uuid:` and a random UUID, and `agent_name_hint` set to `Sentient Systems`. It saves the issued `client_id` from the callback, which every later sign-in and refresh uses.

  A later sign-in sends the last ID token as `id_token_hint`. The bridge checks the ID token, and that the granted scopes include `chatgpt.tokens.use.direct`.
- **Tokens.** `auth/openai.json` in the config file's folder holds the client ID, the host ID, and the tokens. The config file never does, because users may share it, and the refresh token changes on every refresh.

  The terminal bridge saves the tokens with no question. A GUI will ask the user to opt in to saving them, and without it the user signs in on each start.
- **Refresh.** Before each request, the bridge checks the access token's expiry. With less than a minute left, it refreshes the token first. A request that comes during a refresh waits for that refresh, so only one runs at a time.

  A request refused with 401 refreshes once and tries again. A refused refresh clears the tokens, and the picker asks to sign in again on the next start.
- **Calls.** The OpenAI model gets a `fetch` that sets the current token on each request. Each call goes to the Responses API with `store: false`, the system prompt in `instructions`, streamed, and with none of the fields the plan rejects.
- **Model list.** The picker lists the models right after `signIn`, so the list's request uses that token. It reads `/v1/models`, which has its own reply shape on a plan, and keeps the entries whose `visibility` is `list`.
- **First use.** After the first sign-in, the bridge logs "You're using your ChatGPT plan", with the usage page.
- **Failures.** A usage limit is a failure marked `limit`. The agent loop logs it with `https://chatgpt.com/settings/usage`, and stops the run as a run spending limit does. An account that isn't eligible is an `auth` failure that names the plan.
- **Price.** A plan has no price per token, so `model.price` stays blank. The log shows tokens with no cost, and only the token [spending limits](../agents/turn-loop.md#stopping) apply.

[findings/plan-access.md](../../findings/plan-access.md#openai) has OpenAI's URLs, fields, and error codes.

## Decisions

| Decision | Reason |
| --- | --- |
| The access token refreshes only when less than a minute is left | Each refresh replaces the refresh token. A refresh on every request adds a round trip and more chances of `refresh_token_reused` |
| The plan model gets its token through `fetch` on each request | The picker builds the model once, and a game lasts longer than the hour a token lasts |
| Plan tokens live in `auth/`, not the config file | Users may share the config file. The refresh token changes on each refresh, and rewriting the config file each hour would risk the user's edits |
| Only a GUI asks before saving plan tokens | A terminal user runs the bridge on their own computer, and a question on every start adds a step. A GUI has room for the setting, and a user on a shared computer may not want a sign-in kept on disk |
| A usage limit stops the run as a run spending limit does | Every later call fails until the plan resets, and the bridge can't tell when that is. Forced end turns would play turn after turn with no model. A stopped run resumes the same turn on the next start |
