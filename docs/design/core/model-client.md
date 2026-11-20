# Model client

How the bridge calls a model: one interface over every provider, through the Vercel AI SDK. Part of the [bridge](bridge.md).

`models.yaml` maps each provider and operation to a model. Testing fills that table.

`callModel(model, request)` in `src/model/client.ts` sends a system prompt, the messages, and the tools, and returns the model's text and tool calls. Each tool has a name, a description, and a JSON Schema for its input, as the MCP tools do. The client returns each tool call without running it.

`providerModel(config, provider, modelId)` in `src/model/providers.ts` builds the model for one provider: Anthropic, OpenAI, or Google, each through its `@ai-sdk/` package. It reads the API key from `providers` in the [config file](settings.md), and fails with the field to set when the key is empty or missing.

## Decisions

| Decision | Reason |
| --- | --- |
| Any LLM provider, through the Vercel AI SDK | Users bring their own provider. Testing decides which models are good enough |
| Anthropic, OpenAI, and Google first | Three providers give testing a choice of models from the start. Another provider is one package and one line |
| An empty key fails before the SDK sees it | The SDK falls back to an environment variable, such as `ANTHROPIC_API_KEY`, when the key is empty. The config file stays the only place keys come from |
| The model client returns tool calls and doesn't run them | The agent loop runs each call through the MCP server, so it can count actions and stop at a turn limit |
