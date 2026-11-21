# Phase 2: done steps

The finished steps of [phase 2](README.md). The step table's `#` column sets their order.

## Model client

Pull request: feat(core): add the model client.

It added the model client, which calls Anthropic, OpenAI, or Google through the Vercel AI SDK, and a picker that asks for the provider, the model, and the effort when the bridge starts.

Each model's price, tool support, and effort levels come from OpenRouter's public model list. Each call logs its tokens and cost, and retries a rate limit or a server error. `npm run ask` returned a tool call from each provider, and a refused key named its config field.

- The client, the providers, the model list, the picker, the prices, the failures, and `npm run ask` are in [design/core/model-client.md](../../design/core/model-client.md).
- The `providers` and `model` fields, and the environment variables that fill a blank key, are in [design/core/settings.md](../../design/core/settings.md).
