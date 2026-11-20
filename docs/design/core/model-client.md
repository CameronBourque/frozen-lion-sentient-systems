# Model client

How the bridge calls a model: one interface over every provider, through the Vercel AI SDK. Part of the [bridge](bridge.md).

`models.yaml` maps each provider and operation to a model. Testing fills that table.

`callModel(model, request)` in `src/model/client.ts` sends a system prompt, the messages, and the tools, and returns the model's text and tool calls. Each tool has a name, a description, and a JSON Schema for its input, as the MCP tools do. The client returns each tool call without running it.

## Decisions

| Decision | Reason |
| --- | --- |
| Any LLM provider, through the Vercel AI SDK | Users bring their own provider. Testing decides which models are good enough |
| The model client returns tool calls and doesn't run them | The agent loop runs each call through the MCP server, so it can count actions and stop at a turn limit |
