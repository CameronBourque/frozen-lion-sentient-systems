# Preset launcher

Add a bridge tool that starts a test preset from the main menu, with a fixed map seed, so test runs need no clicks through the setup screen. The presets are in [testing.md](../../design/testing.md#presets). Part of [phase 2](README.md).

This step uses the calls that the [front-end probe](front-end-probe.md) records in [lua/state-list.md](../../findings/lua/state-list.md). If Lua can't press the loading screen's button, the tool waits for the player's click, and the [smoke test](smoke-test.md) and the [MVP gate](mvp-gate.md) still run.

## Tasks

1. **Preset files.** Add `packages/core/bridge/presets/smoke.yaml` and `mvp-gate.yaml` from the presets table, each with a fixed map seed. Check each file with a `zod` schema. Commit: `feat(core): add the test presets`.
2. **Game setup.** Add `npm run preset -- <name>`, which sets the map, players, seed, and options from the preset file in the front-end state.

   The core mod must be on in **Additional Content**. Check that before you start, and log a warning when it is off. Commit: `feat(core): set up a game from a test preset`.
3. **Game start.** After the setup, start the game and wait for `GAME_READY`. Commit: `feat(core): start a test preset from the main menu`.

## Done when

From the main menu, `npm run preset -- smoke` starts a game that matches the smoke test row in [testing.md](../../design/testing.md#presets). Two runs give the same map.

## Record

- The preset files and the launcher, in [testing.md](../../design/testing.md#presets).
