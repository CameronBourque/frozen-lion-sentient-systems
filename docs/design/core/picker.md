# Model picker

How you pick the run mode, provider, model, and effort when the bridge starts, and where the model's price comes from. Part of the [model client](model-client.md).

## Menus

When the bridge starts, `chooseModel` in `src/model/choose.ts` runs the picker in a terminal, or checks the saved model without one. It returns the run mode, which is API key without a terminal, or nothing when the user cancels.

In a terminal, `pickModel(config, io)` in `src/model/picker.ts` first asks for the **Run mode**, from `RUN_MODES` in `src/model/providers/provider.ts`, as [run-modes.md](run-modes.md#picker) describes. Then it asks three menus, each starting on the saved choice:

1. **Provider**, from the providers that can play in the run mode. With only one, the picker skips this menu, unless it needs a sign-in.
2. **Model**, from the provider's list, by name, ID, and price. Any other mode shows no price and leaves it blank.
3. **Effort**, from the levels the model supports, with `provider-default` first. `effortsFor` in `src/model/model-facts.ts` reads them from OpenRouter's list:
   - every level for a model OpenRouter doesn't list,
   - only `provider-default` for a model without reasoning,
   - `provider-default` and the model's levels, when OpenRouter lists them, with the level that `provider-default` means, such as `provider-default (high)`,
   - otherwise every level, but `none` only when reasoning can be turned off.

The model menu lists the provider's models from its own API, as [model-client.md](model-client.md#model-lists) describes. It keeps only the models that OpenRouter lists with `tools`.

That drops speech, image, embedding, and realtime models, which OpenRouter lists without tools or not at all. When OpenRouter's list can't be read and there is no cache, the menu lists every model, with a warning.

The bridge saves the choice to `model` in the config file with `saveModel`, which keeps the file's comments. Ctrl+C in a menu exits the bridge.

When the list fails, the picker logs a warning and asks what to do: pick another provider, or try again when only one can play, pick another run mode, use the saved model, or quit. The first row is never the saved model, and the saved model is a row only when it can play.

`askMenu` in `src/model/menu.ts` draws a menu that the arrow keys and Enter answer. Page Up, Page Down, Home, and End jump. A list longer than 5 rows scrolls in a window, with a marker when there are more rows above or below.

Without a terminal, the bridge uses the saved model. `savedModelWarning` warns when no model is picked, or when its provider has no key, because then agents can't play.

## Model facts

`cachedFacts` and `priceFor` in `src/model/model-facts.ts` look up facts about each model, such as its price, in OpenRouter's public model list, while the picker lists the models. It gives each provider's own price.

OpenRouter names a model `anthropic/claude-opus-5.5` where Anthropic's API says `claude-opus-5-5`, so the lookup counts a dot and a dash as the same.

It also finds a model whose ID ends in a release date, which Anthropic uses for older models, by its ID without the date. It skips variants such as `:batch`.

The bridge keeps the facts in `cache/models.json` in the config file's folder, and fetches it again once the copy is a day old. When the fetch fails, an older copy still serves.

The picked model gets the list's price, unless you saved a price for the same model. When the file can't be read, or has no price for the model, the picker warns and the price stays blank.

## Decisions

| Decision | Reason |
| --- | --- |
| You pick the model, with no model table in the repo | Models change faster than releases. The providers' own lists are current, and no one has to keep a table up to date |
| The model menu keeps the models OpenRouter lists with tools | The providers' lists say nothing about tools, or mix in speech, image, and embedding models. A brand-new model shows once OpenRouter lists it, usually the same day |
| The picker asks on each start, from the saved choice | Enter three times keeps the model, and a new model is a few keys away. A choice made once and hidden in the file is easy to forget |
| A long menu scrolls in a window of 5 rows, not pages | The newest models come first and the menu starts on the saved choice, so most picks need little scrolling. 10 rows didn't fit VS Code's default terminal panel |
| The menu uses `node:readline`, with no prompt package | Raw mode and keypress events are in Node. The menu is short, and its logic is tested without a terminal |
| Model facts come from OpenRouter's public model list | No library or provider API gives a price. Its prices match the providers' own, it needs no key, and it also lists each model's tool support and effort levels |
| The model facts are cached for a day | The list is about a megabyte, and prices change rarely. Without the cache, every start in a terminal waits for it |
| Each price the user saved for the same model wins over the list, and a blank one takes the list's | The user may have entered it, such as a discount the list doesn't know. A price saved before the cache prices existed gains them |
| Picking another model replaces the price | The price belonged to the old model, and a stale price gives a wrong cost |
| After a failed list, the user chooses the saved model, and Enter never does | The saved model may cost more than the user meant to spend. A switch the user didn't see could run it for a whole game |
| The effort menu offers only the model's own levels | The SDK swaps an unsupported level for another without asking, so a pick of `minimal` can run at `low`. OpenRouter lists each model's levels |
