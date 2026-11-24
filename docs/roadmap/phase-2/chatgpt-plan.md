# ChatGPT plan

Turn on the **Subscription token** run mode for OpenAI, so agents can play on a ChatGPT Plus or Pro plan. The design is in [run-modes.md](../../design/core/run-modes.md#subscription-token), and the provider's rules are in [plan-access.md](../../findings/plan-access.md#openai). Part of [phase 2](README.md).

## Tasks

1. **Sign-in facts.** Answer questions 5 to 8 in [plan-access.md](../../findings/plan-access.md#method) from OpenAI's docs. Commit: `docs: record the ChatGPT plan sign-in facts`.
2. **Streaming.** Make `callModel` stream every call with `streamText`, in every run mode, as [model-client.md](../../design/core/model-client.md) describes. Rework `modelFailure` for errors that arrive in the stream.

   Check that the client tests still pass for each provider. Commit: `refactor(core): stream every model call`.
3. **Sign-in.** Add `signIn` in `src/model/sign-in/openai.ts`: the browser sign-in with PKCE, the callback on `127.0.0.1`, the first-time registration, and the token refresh. Store the client ID, the host ID, and the tokens in `auth/openai.json`.

   Test it with a fake OAuth server, including a refused refresh, two refreshes at once, and a 401 that refreshes once. Commit: `feat(core): sign in with a ChatGPT plan`.
4. **Calls.** Build the OpenAI model in the subscription mode with a `fetch` that sets the current token on each request. Send `store: false` and the system prompt in `instructions`. List the models from `/v1/models` with the token.

   Replace the `auth` flag on a failed call with a `kind` of `auth`, `limit`, or `other`. Mark a usage limit `limit`, and an account that isn't eligible `auth`. Commit: `feat(core): call OpenAI on a ChatGPT plan`.
5. **Menu.** Add `subscription` to OpenAI's `modes` in `src/model/providers/openai.ts`, with `signIn`. Make the picker call `signIn` after the provider menu.

   Show "Continue with ChatGPT" when there is no valid token, and log the first-use message after the first sign-in. Commit: `feat(core): offer the ChatGPT plan in the picker`.
6. **Live check.** Run the [plan-access.md](../../findings/plan-access.md#method) method for questions 1 and 2, and record the results. Commit: `docs: record the ChatGPT plan check`.
7. **License.** Choose the repo's license and add it as `LICENSE` at the repo root. OpenAI allows plan usage only for open-source apps, as [plan-access.md](../../findings/plan-access.md#openai) says. Commit: `chore: add the license`.

## Done when

All of these hold on a ChatGPT Plus plan:

- `npm run ask` signs in through the browser, lists the plan's models, and prints the tool call.
- The `model_call` record has nonzero input and output tokens and no cost.
- With an expired access token in `auth/openai.json`, the next start refreshes it with no browser.
- `npm run ask` in the API key mode still prints the tool call for each provider.

The repo has a `LICENSE` file.

## Record

- The answers to questions 1, 2, and 5 to 8, in [plan-access.md](../../findings/plan-access.md).
- `auth/` and its files, in [settings.md](../../design/core/settings.md).
- The chosen license and why, in [distribution.md](../../design/distribution.md).
- Any change to the sign-in or the calls, in [run-modes.md](../../design/core/run-modes.md#subscription-token).
- Any change to streaming or failures, in [model-client.md](../../design/core/model-client.md).
