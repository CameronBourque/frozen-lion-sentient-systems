# Model client

Add the model client, which calls the configured provider through the Vercel AI SDK, and a picker where you choose the model and its effort when the bridge starts. This step doesn't need the game. Part of [phase 2](README.md).

## Tasks

1. **Interface.** Add `src/model/client.ts` with one function that takes a system prompt, messages, and tools, and returns the model's text and tool calls. Build it on the `ai` package. Test it with the SDK's mock model. Commit: `feat(core): add the model client`.
2. **Providers.** Add the Anthropic, OpenAI, and Google provider packages, and read each provider's API key from `providers` in the config file, never from the game. Commit: `feat(core): add the Anthropic, OpenAI, and Google providers`.
3. **Model setting.** Add `model` to the config file, with `provider`, `id`, and `effort`, all blank to start. `effort` is one of the AI SDK's `reasoning` levels, and the client passes it on each call. Commit: `feat(core): add the model setting`.
4. **Model list.** List a provider's models through its own API, with the user's key. Keep only the models that write text and call tools. When the list fails, log a warning and keep the saved model. Commit: `feat(core): list each provider's models`.
5. **Picker.** When the bridge starts in a terminal, show three menus that the arrow keys and Enter answer: the provider, the model, and the effort. Each menu starts on the saved choice. The provider menu lists only the providers with a key, and is skipped when only one has a key.

   Save the choice to `model` in the config file, and keep the file's comments. With no terminal, use the saved choice and log it. A blank or stale choice with no terminal logs a warning, and agents can't play. Commit: `feat(core): pick the model when the bridge starts`.
6. **Environment keys.** Fill a blank key from `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, or `GOOGLE_API_KEY`. A key in the config file wins, and the file never gets the environment's key. Commit: `feat(core): read API keys from environment variables`.
7. **Usage.** Return the input and output tokens of each call, and log them at the decisions level. Add `price` to `model`, with `input` and `output` in US dollars per million tokens, blank to start.

   When the price is set, the log shows each call's cost. A new model in the picker clears the price, because the price belonged to the old model. Commit: `feat(core): log tokens and cost per model call`.
8. **Errors.** Retry a rate limit or a server error with backoff, up to 3 times. On an auth error, log a warning that names the config field, and stop the turn. Commit: `feat(core): retry model calls`.
9. **Script.** Add `npm run ask`, which sends one prompt with one fake tool to the chosen model and prints the tool call. Commit: `chore(core): add a script that tests the model`.

## Done when

- The picker lists the models of each of the three providers, and its choice is in the config file afterward.
- `npm run ask` returns a tool call from each of the three providers.
- The log shows each call's tokens, and its cost when `price` is set.
- A wrong API key gives a warning that names `apiKey`.

## Record

- The client, the providers, the model list, and the picker, in [model-client.md](../../design/core/model-client.md).
- The `model` fields, in [settings.md](../../design/core/settings.md).
