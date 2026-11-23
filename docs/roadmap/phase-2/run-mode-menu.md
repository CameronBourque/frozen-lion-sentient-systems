# Run mode menu

Add a file for each provider and a **Run mode** menu to the picker, with only **API key** working. The design is in [run-modes.md](../../design/core/run-modes.md). Part of [phase 2](README.md).

## Tasks

1. **Providers.** Add `src/model/providers/` with `RunMode`, `ModeSupport`, and `ProviderDef` in `provider.ts`, `apiKeyMode` in `api-key.ts`, one file for each provider with only `api-key` in its `modes`, and `PROVIDERS` in `index.ts`.

   Move the factories and the key check from `src/model/providers.ts` into them, and have the picker read `PROVIDERS`, with no change in how it plays. Commit: `refactor(core): move each provider into its own file`.
2. **Menu.** Ask for the run mode before the provider, starting on **API key**, from a table of the modes and their labels in `provider.ts`. **API key** leads to the provider, model, and effort menus, and **Quit** exits.

   A mode that no provider has in `modes` reads `(not available yet)`, warns when chosen, and asks again. **API key** with no ready provider warns with the reason and asks again. The picker's result carries the run mode.

   Test the menu with a fake `PickerIo`, and with a fake `PROVIDERS` that has a provider with a second mode. Commit: `feat(core): ask for the run mode`.
3. **Another run mode.** Add **Pick another run mode** to the **What now?** menu. Commit: `feat(core): offer another run mode after a failed model list`.
4. **Log line.** Name the run mode in the `model_chosen` log line. Commit: `feat(core): name the run mode in the model log line`.

## Done when

All of these hold in a terminal:

- `npm run ask` shows the **Run mode** menu with all four modes and **Quit**, starting on **API key**, and **API key** picks a model and calls it as before.
- **Subscription token**, **Agent SDK**, and **CLI** each warn that the mode isn't available yet, and show the menu again.
- With no API key in the config file or the environment, **API key** warns and shows the menu again, and **Quit** exits.
- After a pick, the config file has no run mode, and the log line names it.

## Record

- The **Run mode** menu, its **Quit** row, and the **Pick another run mode** row, in the picker section of [model-client.md](../../design/core/model-client.md#picker).
- Any change to `src/model/providers/`, in [run-modes.md](../../design/core/run-modes.md#providers).
