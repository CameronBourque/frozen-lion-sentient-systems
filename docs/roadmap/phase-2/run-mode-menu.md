# Run mode menu

Add the four run modes to the config file and a **Run mode** menu to the picker, with only **API key** working. The design is in [run-modes.md](../../design/core/run-modes.md). Part of [phase 2](README.md).

## Tasks

1. **Mode table.** Add `src/model/run-modes.ts` with `RUN_MODES`, which lists Anthropic, OpenAI, and Google as `ready` in `api-key` and no provider in the other modes. Add `model.mode` to the config file, with `api-key` as the default. Commit: `feat(core): add run modes to the config`.
2. **Menu.** Ask for the run mode before the provider, starting on the saved mode. **API key** leads to the provider, model, and effort menus. Each mode with no ready provider reads `(not available yet)`, warns when chosen, and asks again.

   Test the menu with a fake `PickerIo`, and a flagged provider with its constant injected both ways. Commit: `feat(core): ask for the run mode`.

## Done when

All of these hold in a terminal:

- `npm run ask` shows the **Run mode** menu with all four modes, and **API key** picks a model and calls it as before.
- **Subscription token**, **Agent SDK**, and **CLI** each warn that the mode isn't available yet, and show the menu again.
- A config file with no `model.mode` loads, and the bridge saves `mode: api-key` after the pick.

## Record

- The **Run mode** menu, in the picker section of [model-client.md](../../design/core/model-client.md#picker).
- `model.mode` and its default, in [settings.md](../../design/core/settings.md).
