# Model client

How the bridge calls a model: one interface over every provider, through the Vercel AI SDK. Part of the [bridge](bridge.md).

You pick the model and its effort in `model` in the [config file](settings.md), through a picker when the bridge starts. The picker lists each provider's models from its own API.

`callModel(model, effort, request)` in `src/model/client.ts` sends a system prompt, the messages, and the tools, with the effort as the SDK's `reasoning` setting, and returns the model's text and tool calls.

Each tool has a name, a description, and a JSON Schema for its input, as the MCP tools do. The client returns each tool call without running it.

`providerModel(config, provider, modelId)` in `src/model/providers.ts` builds the model for one provider: Anthropic, OpenAI, or Google, each through its `@ai-sdk/` package. It reads the API key from `providers` in the [config file](settings.md), and fails with the field to set when the key is empty or missing.

`listModels(provider, apiKey)` in `src/model/list-models.ts` lists a provider's models through its own API, with `fetch`, and reads every page. It keeps only the models that write text and call tools:

- **Anthropic** lists only chat models, newest first, so it keeps them all.
- **OpenAI** lists every kind of model with no capabilities, so it keeps the IDs that start with `gpt-` or `o` and a digit. It drops speech, image, embedding, and search models by words in the ID, and dated snapshots, which repeat an alias. The newest comes first.

  A snapshot ends in the full date, or in an older one, in the month and day.
- **Google** keeps the `gemini-` models that support `generateContent`, and drops speech, image, and embedding models by words in the ID.

A refused request, a network error, or an answer of the wrong shape fails the whole list, with a reason the picker can show.

## Decisions

| Decision | Reason |
| --- | --- |
| Any LLM provider, through the Vercel AI SDK | Users bring their own provider. Testing decides which models are good enough |
| Anthropic, OpenAI, and Google first | Three providers give testing a choice of models from the start. Another provider is one package and one line |
| An empty key fails before the SDK sees it | The SDK falls back to an environment variable, such as `ANTHROPIC_API_KEY`, when the key is empty. The config file stays the only place keys come from |
| You pick the model, with no model table in the repo | Models change faster than releases. The providers' own lists are current, and no one has to keep a table up to date |
| The effort levels are a record checked against the SDK's `reasoning` type | The SDK exports the levels only as a type. A record needs every level and allows no others, so typecheck fails when an SDK update adds or drops one |
| The model lists come from each provider's API, with `fetch` | The SDK packages hold their model names only as types. `fetch` is in Node, so the lists need no package |
| OpenAI's list is filtered by words in the ID | Its API gives no capabilities. A new kind of model may show in the menu until a word is added |
| The model client returns tool calls and doesn't run them | The agent loop runs each call through the MCP server, so it can count actions and stop at a turn limit |
