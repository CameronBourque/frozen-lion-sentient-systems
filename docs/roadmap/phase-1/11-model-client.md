# Step 11: Model client

Add the model client, which calls the configured provider through the Vercel AI SDK, and `models.yaml`, which maps each provider and operation to a model. This step doesn't need the game. Part of [phase 1](README.md).

## Tasks

1. **Interface.** Add `src/model/client.ts` with one function that takes a system prompt, messages, and tools, and returns the model's text and tool calls. Build it on the `ai` package. Test it with the SDK's mock model. Commit: `feat(core): add the model client`.
2. **Providers.** Add the Anthropic and OpenAI provider packages, and read each provider's API key from `providers` in the config file, never from the game. Commit: `feat(core): add the Anthropic and OpenAI providers`.
3. **Model table.** Add `packages/agents/models.yaml`, with the model for each provider and each operation. Phase 1 has one operation, `turn`. Check the file with a `zod` schema when the bridge starts. Commit: `feat(core): add the model table`.
4. **Usage.** Return the input and output tokens of each call, and log them at the decisions level. Add a price table to `models.yaml` so the log shows each call's cost. Commit: `feat(core): log tokens and cost per model call`.
5. **Errors.** Retry a rate limit or a server error with backoff, up to 3 times. On an auth error, log a warning that names the config field, and stop the turn. Commit: `feat(core): retry model calls`.
6. **Script.** Add `npm run ask`, which sends one prompt with one fake tool to the configured model and prints the tool call. Commit: `chore(core): add a script that tests the model`.

## Done when

`npm run ask` returns a tool call from each provider, and the log shows its tokens and cost. A wrong API key gives a warning that names `apiKey`.

## Record

- The client, the providers, and the model table, in [bridge.md](../../design/core/bridge.md).
- The `models.yaml` location, in [knowledge-files.md](../../design/knowledge-files.md#file-layout).
