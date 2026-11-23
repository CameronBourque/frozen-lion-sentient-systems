# ChatGPT plan

Turn on the **Subscription token** run mode for OpenAI, so agents can play on a ChatGPT Plus or Pro plan. The design is in [run-modes.md](../../design/core/run-modes.md#subscription-token), and the provider's rules are in [plan-access.md](../../findings/plan-access.md#openai). Part of [phase 2](README.md).

## Tasks

1. **Sign-in.** Add `signIn` in `src/model/sign-in/openai.ts`: the browser sign-in with PKCE, the callback on `127.0.0.1`, the first-time registration, and the token refresh. Store the client ID, the host ID, and the tokens in `auth/openai.json`.

   Test it with a fake OAuth server, including a refused refresh and two refreshes at once. Commit: `feat(core): sign in with a ChatGPT plan`.
2. **Calls.** Build the OpenAI model with the token in the subscription mode. Stream each call with `store: false`, and list the models from `/v1/models` with the token.

   Return a usage limit as a failure marked `limit`, and an account that isn't eligible as an `auth` failure. Commit: `feat(core): call OpenAI on a ChatGPT plan`.
3. **Menu.** Add `subscription` to OpenAI's `modes` in `src/model/providers/openai.ts`. Show "Continue with ChatGPT" when there is no valid token, and log the first-use message after the first sign-in. Commit: `feat(core): offer the ChatGPT plan in the picker`.
4. **Live check.** Run the [plan-access.md](../../findings/plan-access.md#method) method for questions 1 and 2, and record the results. Commit: `docs: record the ChatGPT plan check`.

## Done when

All of these hold on a ChatGPT Plus plan:

- `npm run ask` signs in through the browser, lists the plan's models, and prints the tool call.
- The `model_call` record has nonzero input and output tokens and no cost.
- With an expired access token in `auth/openai.json`, the next start refreshes it with no browser.

## Record

- The answers to questions 1 and 2, in [plan-access.md](../../findings/plan-access.md).
- `auth/` and its files, in [settings.md](../../design/core/settings.md).
- Any change to the sign-in or the calls, in [run-modes.md](../../design/core/run-modes.md#subscription-token).
