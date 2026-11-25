# ChatGPT plan

Turn on the **Subscription token** run mode for OpenAI, so agents can play on a ChatGPT Plus or Pro plan. The design is in [subscription-token.md](../../design/core/subscription-token.md), and the provider's rules are in [plan-access/openai.md](../../findings/plan-access/openai.md). Part of [phase 2](README.md).

## Tasks

1. **Sign-in facts.** Record OpenAI's sign-in, refresh, model list, and request rules in [plan-access/openai.md](../../findings/plan-access/openai.md) from OpenAI's docs. Commit: `docs: record the ChatGPT plan sign-in facts`.
2. **Streaming.** Make `callModel` stream every call with `streamText`, in every run mode, as [model-client.md](../../design/core/model-client.md) describes. Rework `modelFailure` for errors that arrive in the stream.

   Check that the client tests still pass for each provider. Commit: `refactor(core): stream every model call`.
3. **Run mode builder.** Split `apiKeyMode` in `src/model/providers/api-key.ts` into a credential type and one builder that makes a `ModeSupport` from a credential, a model factory, and a lister.

   Make the API key credential read the key that `withEnvironmentKeys` resolves, so the key's source doesn't change.

   Check that the picker and model list tests pass unchanged. Commit: `refactor(core): build run modes from a credential, a factory, and a lister`.
4. **Sign-in.** Add `signIn` in `src/model/sign-in/openai.ts`: the browser sign-in with PKCE, the callback on `127.0.0.1`, the first-time registration, and the token refresh. Store the client ID, the host ID, and the tokens in `auth/openai.json`.

   Test it with a fake OAuth server, including a refused refresh, two refreshes at once, and a 401 that refreshes once. Three commits:

   1. Rename the credential's `value` and `current` to `source` and `secret`, and make `secret` return a failure in place of throwing. Commit: `refactor(core): name a credential's source and secret`.
   2. The token store in `auth/openai.json`, with its refresh. Commit: `feat(core): keep and refresh ChatGPT plan tokens`.
   3. The browser sign-in, with its first-time registration and the ID token check. Commit: `feat(core): sign in with a ChatGPT plan`.
5. **Calls.** Three commits:

   1. Replace the `auth` flag on a failed call with a `kind` from a table of every known failure: `auth`, each plan error code, and `other` for the rest. Give the auth fix for the run mode. Commit: `refactor(core): mark a failed call with a kind`.
   2. List the models from `/v1/models` with the token, with a lister that reads the plan's `models` array. Commit: `feat(core): list the models on a ChatGPT plan`.
   3. Add the plan credential, whose source is the token store. Build the OpenAI model in the subscription mode with a `fetch` that sets the current token on each request. Send `store: false` and the system prompt in `instructions`.

      Make the `fetch` turn a usage limit's 429 into a status the SDK doesn't retry, since every retry fails until the plan resets. Commit: `feat(core): call OpenAI on a ChatGPT plan`.
6. **Menu.** Three commits:

   1. Turn `PROVIDERS` into `providers(folder, log)`, which passes the config file's folder and the logger to `openai(folder, log)`, so the plan's token store finds `auth/`.

      Add `subscription` to OpenAI's `modes` in `src/model/providers/openai.ts`, with a `signIn` of a menu label and a `run`. Commit: `feat(core): add OpenAI's subscription mode`.
   2. Offer a provider whose mode has `signIn` even when it isn't ready, with "Continue with ChatGPT" as its row, and always show the provider menu then, so the browser never opens unasked.

      Run `signIn` after the provider menu, and log the first-use message after a browser sign-in. Commit: `feat(core): offer the ChatGPT plan in the picker`.
   3. Make `chooseModel` return the picked run mode, and `scripts/ask.ts` build the model and call it in that mode, not always the API key mode. Commit: `feat(core): ask in the picked run mode`.
7. **Live check.** Sign in on a ChatGPT Plus plan, run `npm run ask`, and record the results in [plan-access/openai.md](../../findings/plan-access/openai.md#results). Commit: `docs: record the ChatGPT plan check`.
8. **License.** Choose the repo's license and add it as `LICENSE` at the repo root. OpenAI allows plan usage only for open-source apps, as [plan-access/openai.md](../../findings/plan-access/openai.md) says. Commit: `chore: add the license`.

## Done when

All of these hold on a ChatGPT Plus plan:

- `npm run ask` signs in through the browser, lists the plan's models, and prints the tool call.
- The `model_call` record has nonzero input and output tokens and no cost.
- With an expired access token in `auth/openai.json`, the next start refreshes it with no browser.
- `npm run ask` in the API key mode still prints the tool call for each provider.

The repo has a `LICENSE` file.

## Record

- The results of the live check, in [plan-access/openai.md](../../findings/plan-access/openai.md#results).
- `auth/` and its files, in [settings.md](../../design/core/settings.md).
- The chosen license and why, in [distribution.md](../../design/distribution.md).
- The credential type and the mode builder, in [run-modes.md](../../design/core/run-modes.md#providers).
- Any change to the sign-in or the calls, in [subscription-token.md](../../design/core/subscription-token.md).
- Any change to streaming or failures, in [model-client.md](../../design/core/model-client.md).
