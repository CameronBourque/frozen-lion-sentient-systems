# Model client

How the bridge calls a model: one interface over every provider, through the Vercel AI SDK. Part of the [bridge](bridge.md).

You pick the model and its effort in `model` in the [config file](settings.md), through a picker when the bridge starts. The picker lists each provider's models from its own API.

`callModel(target, request)` in `src/model/client.ts` sends a system prompt, the messages, and the tools to the target's model, with the effort as the SDK's `reasoning` setting, and returns the model's text and tool calls. The target also names the provider, for the error messages.

`callModel` streams every call with the SDK's `streamText`, in every run mode, and returns once the stream ends.

Each tool has a name, a description, and a JSON Schema for its input, as the MCP tools do. The client returns each tool call without running it.

Each provider's API key mode, from `apiKeyMode` in `src/model/providers/api-key.ts`, builds the model for that provider: Anthropic, OpenAI, or Google, each through its `@ai-sdk/` package. [run-modes.md](run-modes.md#providers) has the provider files.

It reads the API key from `providers` in the [config file](settings.md), which an environment variable fills when it is blank, and fails with the field to set when the key is empty or missing.

`listModels(provider, lister, credential)` in `src/model/list-models.ts` lists a provider's models through its own API, with `fetch`, and reads every page.

The credential is the API key, or the plan token in a subscription token mode. Each provider file has its own lister, with the list's URL, headers, and page shape.

The provider's list shows the models the user's key can use. Anthropic lists the newest first, and the OpenAI list is sorted newest first.

OpenAI lists each dated snapshot beside its alias, so the list drops an ID that ends in a date: the full date, or in an older one, the month and day. Google's IDs lose their `models/` prefix, which the SDK doesn't take.

The picker keeps only the models that OpenRouter lists with `tools`. That drops speech, image, embedding, and realtime models, which OpenRouter lists without tools or not at all. When OpenRouter's list can't be read and there is no cache, the menu lists every model, with a warning.

A refused request, a network error, or an answer of the wrong shape fails the whole list, with a reason the picker can show.

## Failures

`callModel` returns a failure instead of throwing. Each failure has a `kind`: `auth`, `limit`, or `other`.

- **A rate limit or a server error**, such as 429, 500, or 529, retries up to 3 times through the SDK's own retry, with backoff from 2 seconds, or after the provider's `Retry-After`. The SDK retries only before the stream starts.

  After the last try, the failure gives the number of tries and the last error.
- **A refused key**, 401 or 403, doesn't retry. The failure is marked `auth`, and its message names `providers.<provider>.apiKey` and the key's environment variable. The agent loop logs it as a warning and stops the turn.
- **A plan's usage limit** is marked `limit`, as [subscription-token.md](subscription-token.md) describes.
- **An error after the stream starts**, or any other error, is marked `other` and gives its message.

## Usage

`callModel` returns each call's input and output tokens, and how many input tokens it read from the provider's prompt cache or wrote to it. Each provider reports these counts itself. A count the provider doesn't report is 0.

`logModelCall` in `src/model/usage.ts` logs the tokens at the decisions level, as `model_call`. The record also has the call's cost in US dollars, with uncached input, cache reads, cache writes, and output each at its own price in `model.price`.

A cache read or write with no cache price counts as plain input, at the input price. When the call used input or output with no price, the record has no cost.

## Picker

When the bridge starts, `chooseModel` in `src/model/choose.ts` runs the picker in a terminal, or checks the saved model without one.

In a terminal, `pickModel(config, io)` in `src/model/picker.ts` first asks for the **Run mode**, from `RUN_MODES` in `src/model/providers/provider.ts`, as [run-modes.md](run-modes.md#picker) describes. Then it asks three menus, each starting on the saved choice:

1. **Provider**, from the providers that can play in the run mode. With only one, the picker skips this menu.
2. **Model**, from the provider's list, by name, ID, and price.
3. **Effort**, from the levels the model supports, with `provider-default` first. `effortsFor` in `src/model/model-facts.ts` reads them from OpenRouter's list:
   - every level for a model OpenRouter doesn't list,
   - only `provider-default` for a model without reasoning,
   - `provider-default` and the model's levels, when OpenRouter lists them, with the level that `provider-default` means, such as `provider-default (high)`,
   - otherwise every level, but `none` only when reasoning can be turned off.

`cachedFacts` and `priceFor` in `src/model/model-facts.ts` look up facts about each model, such as its price, in OpenRouter's public model list, while the picker lists the models. The list gives each provider's own price, with no markup.

OpenRouter names a model `anthropic/claude-opus-5.5` where Anthropic's API says `claude-opus-5-5`, so the lookup counts a dot and a dash as the same.

It also finds a model whose ID ends in a release date, which Anthropic uses for older models, by its ID without the date. It skips variants such as `:batch`.

The bridge keeps the facts in `cache/models.json` in the config file's folder, and fetches it again once the copy is a day old. When the fetch fails, an older copy still serves.

The picked model gets the list's price, unless you saved a price for the same model. When the file can't be read, or has no price for the model, the picker warns and the price stays blank.

The bridge saves the choice to `model` in the config file with `saveModel`, which keeps the file's comments. Ctrl+C in a menu exits the bridge.

When the list fails, the picker logs a warning and asks what to do: pick another provider, or try again when only one can play, pick another run mode, use the saved model, or quit. The first row is never the saved model, and the saved model is a row only when it can play.

`askMenu` in `src/model/menu.ts` draws a menu that the arrow keys and Enter answer. Page Up, Page Down, Home, and End jump. A list longer than 5 rows scrolls in a window, with a marker when there are more rows above or below.

Without a terminal, the bridge uses the saved model. `savedModelWarning` warns when no model is picked, or when its provider has no key, because then agents can't play.

## Checking a model

`npm run ask` checks a model without the game. It reads `tmp/sentient-systems.yaml`, runs the picker in a terminal, and sends the chosen model one prompt with one fake tool, `report_civilization`.

It prints the tool call, such as `report_civilization({"name":"Rome"})`, and logs the call's tokens and cost.

It exits with code 1 when the config has errors, no model can be built, the call fails, or the model calls no tool. A model that writes text and calls no tool doesn't get tools through, and the script prints the text.

## Decisions

| Decision | Reason |
| --- | --- |
| Any LLM provider, through the Vercel AI SDK | Users bring their own provider. Testing decides which models are good enough |
| Anthropic, OpenAI, and Google first | Three providers give testing a choice of models from the start. Another provider is one package and one line |
| An empty key fails before the SDK sees it | The SDK falls back to its own environment variable, such as `GOOGLE_GENERATIVE_AI_API_KEY`, when the key is empty. The bridge reads only the variables in [settings.md](settings.md), so the log always says where a key came from |
| You pick the model, with no model table in the repo | Models change faster than releases. The providers' own lists are current, and no one has to keep a table up to date |
| The effort levels are a record checked against the SDK's `reasoning` type | The SDK exports the levels only as a type. A record needs every level and allows no others, so typecheck fails when an SDK update adds or drops one |
| The model lists come from each provider's API, with `fetch` | The SDK packages hold their model names only as types. `fetch` is in Node, so the lists need no package |
| The model menu keeps the models OpenRouter lists with tools | The providers' lists say nothing about tools, or mix in speech, image, and embedding models. A brand-new model shows once OpenRouter lists it, usually the same day |
| The picker asks on each start, from the saved choice | Enter three times keeps the model, and a new model is a few keys away. A choice made once and hidden in the file is easy to forget |
| A long menu scrolls in a window of 5 rows, not pages | The newest models come first and the menu starts on the saved choice, so most picks need little scrolling. 10 rows didn't fit VS Code's default terminal panel |
| The menu uses `node:readline`, with no prompt package | Raw mode and keypress events are in Node. The menu is short, and its logic is tested without a terminal |
| Model facts come from OpenRouter's public model list | No library or provider API gives a price. Its prices match the providers' own, it needs no key, and it also lists each model's tool support and effort levels |
| The model facts are cached for a day | The list is about a megabyte, and prices change rarely. Without the cache, every start in a terminal waits for it |
| Each price the user saved for the same model wins over the list, and a blank one takes the list's | The user may have entered it, such as a discount the list doesn't know. A price saved before the cache prices existed gains them |
| Cached tokens with no cache price count as plain input, and the log shows a cost only when input and output have prices | Every cached token is still an input token, so the input price is a fair stand-in. Without an input or output price there is nothing to stand in |
| Picking another model replaces the price | The price belonged to the old model, and a stale price gives a wrong cost |
| Retries use the SDK's own retry, with `maxRetries` set to 3 | It already backs off, honors `Retry-After`, and knows which status codes are worth a retry |
| Every call streams, in every run mode | A ChatGPT plan takes only streamed calls. One path for every mode means the API key and plan calls fail, retry, and report usage the same way |
| A failed call returns a failure instead of throwing | A failed call is an ordinary event for the agent loop, which decides what to do. An auth failure stops the turn, because every retry would fail the same way |
| After a failed list, the user chooses the saved model, and Enter never does | The saved model may cost more than the user meant to spend. A switch the user didn't see could run it for a whole game |
| The effort menu offers only the model's own levels | The SDK swaps an unsupported level for another without asking, so a pick of `minimal` can run at `low`. OpenRouter lists each model's levels |
| The model client returns tool calls and doesn't run them | The agent loop runs each call through the MCP server, so it can count actions and stop at a turn limit |
