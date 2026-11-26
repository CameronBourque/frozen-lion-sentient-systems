# Model client

How the bridge calls a model: one interface over every provider, through the Vercel AI SDK. Part of the [bridge](bridge.md).

You pick the model and its effort in `model` in the [config file](settings.md), through the [picker](picker.md) when the bridge starts. The picker lists each provider's models from its own API.

`callModel(target, request)` in `src/model/client.ts` sends a system prompt, the messages, and the tools to the target's model, with the effort as the SDK's `reasoning` setting, and returns the model's text and tool calls. The target also names the provider, for the error messages.

`callModel` streams every call with the SDK's `streamText`, in every run mode, and returns once the stream ends.

Each tool has a name, a description, and a JSON Schema for its input, as the MCP tools do. The client returns each tool call without running it.

Each provider's API key mode, from `apiKeyMode` in `src/model/providers/api-key.ts`, builds the model for that provider: Anthropic, OpenAI, Google, or xAI, each through its `@ai-sdk/` package. [run-modes.md](run-modes.md#providers) has the provider files.

It reads the API key from `providers` in the [config file](settings.md), which an environment variable fills when it is blank, and fails with the field to set when the key is empty or missing.

## Model lists

`listModels(provider, lister, credential)` in `src/model/list-models.ts` lists a provider's models through its own API, with `fetch`, and reads every page.

The credential is the API key, or the plan token in a subscription token mode. Each provider file has its own lister, with the list's URL, headers, and page shape.

The provider's list shows the models the user's key can use. Anthropic lists the newest first, and the OpenAI and xAI lists are sorted newest first.

OpenAI lists each dated snapshot beside its alias, so the list drops an ID that ends in a date: the full date, or in an older one, the month and day. Google's IDs lose their `models/` prefix, which the SDK doesn't take.

xAI's list is `/v1/language-models`, which leaves out its image and video models.

A refused request, a network error, or an answer of the wrong shape fails the whole list, with a reason the picker can show.

## Failures

`callModel` returns a failure instead of throwing. Each failure has a `kind`, from a table in `src/model/client.ts` that lists every failure the bridge knows, with how to spot it and its message. The first row that matches wins. A failure that matches no row is `other`.

- **A rate limit or a server error**, such as 429, 500, or 529, retries up to 3 times through the SDK's own retry, with backoff from 2 seconds, or after the provider's `Retry-After`. The SDK retries only before the stream starts.

  After the last try, the failure gives the number of tries and the last error.
- **A refused credential**, 401 or 403, doesn't retry. It is marked `auth`, with the fix for the run mode in `ModelTarget`. An API key's fix names `providers.<provider>.apiKey` and its variable, and a plan's says to sign in again. The agent loop stops the turn.
- **A plan's error codes** each have a kind, matched in the error's `responseBody`, which also holds a mid-stream `response.failed` frame. [subscription-token.md](subscription-token.md) lists them.
- **An error after the stream starts**, or any other error, is marked `other` and gives its message.

## Usage

`callModel` returns each call's input and output tokens, and how many input tokens it read from the provider's prompt cache or wrote to it. Each provider reports these counts itself. A count the provider doesn't report is 0.

`logModelCall` in `src/model/usage.ts` logs the tokens at the decisions level, as `model_call`. The record also has the call's cost in US dollars, with uncached input, cache reads, cache writes, and output each at its own price in `model.price`.

A cache read or write with no cache price counts as plain input, at the input price. When the call used input or output with no price, the record has no cost.

## Checking a model

`npm run ask` checks a model without the game. It reads `tmp/sentient-systems.yaml`, runs the picker in a terminal, and sends the chosen model one prompt with one fake tool, `report_civilization`, in the picked run mode.

It prints the tool call, such as `report_civilization({"name":"Rome"})`, and logs the call's tokens and cost.

It exits with code 1 when the config has errors, no model can be built, the call fails, or the model calls no tool. A model that writes text and calls no tool doesn't get tools through, and the script prints the text.

## Decisions

| Decision | Reason |
| --- | --- |
| Any LLM provider, through the Vercel AI SDK | Users bring their own provider. Testing decides which models are good enough |
| Anthropic, OpenAI, Google, and xAI | Several providers give testing a choice of models. Another provider is one package and one line |
| An empty key fails before the SDK sees it | The SDK falls back to its own environment variable, such as `GOOGLE_GENERATIVE_AI_API_KEY`, when the key is empty. The bridge reads only the variables in [settings.md](settings.md), so the log always says where a key came from |
| The effort levels are a record checked against the SDK's `reasoning` type | The SDK exports the levels only as a type. A record needs every level and allows no others, so typecheck fails when an SDK update adds or drops one |
| The model lists come from each provider's API, with `fetch` | The SDK packages hold their model names only as types. `fetch` is in Node, so the lists need no package |
| Cached tokens with no cache price count as plain input, and the log shows a cost only when input and output have prices | Every cached token is still an input token, so the input price is a fair stand-in. Without an input or output price there is nothing to stand in |
| Retries use the SDK's own retry, with `maxRetries` set to 3 | It already backs off, honors `Retry-After`, and knows which status codes are worth a retry |
| Every call streams, in every run mode | A ChatGPT plan takes only streamed calls. One path for every mode means the API key and plan calls fail, retry, and report usage the same way |
| Every known failure has its own kind, and `other` is only for the rest | The agent loop decides by kind, and a new failure is one table row |
| A failed call returns a failure instead of throwing | A failed call is an ordinary event for the agent loop, which decides what to do. An auth failure stops the turn, because every retry would fail the same way |
| The model client returns tool calls and doesn't run them | The agent loop runs each call through the MCP server, so it can count actions and stop at a turn limit |
