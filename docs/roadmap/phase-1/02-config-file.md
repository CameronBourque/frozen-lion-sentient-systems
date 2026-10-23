# Step 2: Config file

Give the bridge one config file that marks the agent slot and holds the log level, the provider, and the API key. There are no setup screen changes in phase 1. Part of [phase 1](README.md).

## Tasks

1. **Schema.** Add `src/config.ts` with a `zod` schema and a `schemaVersion` field, as [versioning.md](../../design/versioning.md#bump-rules) requires. Fields:
   - `agents`, a list of `{ playerId, personality, sweat }`, with one entry in phase 1,
   - `logLevel`, one of `off`, `decisions`, or `full`,
   - `provider` and `apiKey`.

   Test that a bad file gives an error that names the field. Commit: `feat(core): add the config schema`.
2. **Load.** Read `sentient-systems.yaml` from the folder that holds the executable, or from the path in `--config`. In development, `npm run dev` passes `--config` with a path under `tmp/`. If the file is missing, write a commented example there, log a warning that names its path, and exit. Commit: `feat(core): load the config file`.
3. **Agent slot.** Drop `AGENT_TURN` events for a player ID that isn't in `agents`. Only listed players start a turn later. Commit: `feat(core): start turns only for configured agents`.
4. **Docs.** In [bridge.md](../../design/core/bridge.md), describe the file under **Settings**, and add a row to `## Decisions` for the location and the format. Commit: `docs: describe the bridge config file`.

## Done when

`npm run dev` with a config that lists player 0 logs the turn for player 0. With player 0 removed from the file, it doesn't. A config with a bad `logLevel` exits with a message that names `logLevel`.

## Record

The file's location, format, and fields, in [bridge.md](../../design/core/bridge.md).
