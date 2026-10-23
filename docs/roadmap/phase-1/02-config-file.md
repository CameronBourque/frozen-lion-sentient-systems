# Step 2: Config file

Give the bridge one config file that holds the log level and an API key for each provider. Agent slots, personalities, and sweat levels come from the save, and there are no setup screen changes in phase 1. Part of [phase 1](README.md).

## Tasks

1. **Schema.** Add `src/config.ts` with a `zod` schema and a `schemaVersion` field, as [versioning.md](../../design/versioning.md#bump-rules) requires. Fields:
   - `logLevel`, one of `off`, `decisions`, or `full`,
   - `providers`, with an `apiKey` for each provider, empty by default.

   Test that a bad file gives an error that names the field. Commit: `feat(core): add the config schema`.
2. **Load.** Read `sentient-systems.yaml` from the folder that holds the executable, or from the path in `--config`. In development, `npm run dev` passes `--config` with a path under `tmp/`. If the file is missing, write a commented example there, log a warning that names its path, and exit. If no provider has a key, log a warning and keep running. Commit: `feat(core): load the config file`.
3. **Docs.** In [bridge.md](../../design/core/bridge.md), describe the file under **Settings**, and add rows to `## Decisions` for the location, the format, and what the file leaves to the save. Commit: `docs: describe the bridge config file`.

## Done when

All of these hold:

- `npm run dev` with no file writes the example to `tmp/sentient-systems.yaml` and exits with a warning that names its path.
- `npm run dev` with a bad `logLevel` exits with a message that names `logLevel`.
- `npm run dev` with a valid file logs the human player's turn in a running game.

## Record

The file's location, format, and fields, in [bridge.md](../../design/core/bridge.md).
