# Phase 2: done steps

The finished steps of [phase 2](README.md). The step table's `#` column sets their order.

## Model client

Pull request: feat(core): add the model client.

It added the model client, which calls Anthropic, OpenAI, or Google through the Vercel AI SDK, and a picker that asks for the provider, the model, and the effort when the bridge starts.

Each model's price, tool support, and effort levels come from OpenRouter's public model list. Each call logs its tokens and cost, and retries a rate limit or a server error. `npm run ask` returned a tool call from each provider, and a refused key named its config field.

- The client, the providers, the model list, the picker, the prices, the failures, and `npm run ask` are in [design/core/model-client.md](../../design/core/model-client.md).
- The `providers` and `model` fields, and the environment variables that fill a blank key, are in [design/core/settings.md](../../design/core/settings.md).

## Personality and sweat level

Pull request: feat(core): add the neutral personality and the balanced sweat level.

It added the neutral personality, the balanced sweat level, and the rules of play as knowledge files in `packages/core/bridge/knowledge/`, which the executable carries as Node SEA assets.

It also added `systemPrompt` and `turnMessage` in `src/agents/prompt.ts`, which build the prompt from them and the state.

The executable, copied alone to an empty folder, read the 3 files. A test builds the prompt from the shipped files and a fixed state. The executable builds its first real prompt in the [agent loop](agent-loop.md) step.

- Where the files live, their format, and the neutral personality are in [design/knowledge-files.md](../../design/knowledge-files.md#file-layout).
- How the prompt is built, and why the state goes in once per turn, are in [design/agents/prompt.md](../../design/agents/prompt.md).
- How the executable carries the files is in [design/distribution.md](../../design/distribution.md), with the asset facts in [findings/build-tooling.md](../../findings/build-tooling.md).
- **Random** resolving to a personality when the game starts is in [design/agents/slot-type.md](../../design/agents/slot-type.md).
