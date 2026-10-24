# Step 15: Preset launcher

Add a bridge tool that starts a test preset from the main menu, with a fixed map seed, so test runs need no clicks through the setup screen. The presets are in [testing.md](../../design/testing.md#presets). Part of [phase 1](README.md).

This step depends on questions 1 and 2 in [state-list.md](../../findings/state-list.md#questions). If Lua can't press the loading screen's button, the tool waits for the player's click, and steps 16 and 17 still run.

## Tasks

1. **Front-end calls.** Read `<game>\Base\Assets\UI\FrontEnd\` to find how the setup screen sets the map, players, seed, and options, and how **Start Game** starts the game. Check from the tuner which calls work in the `MainMenu` or `FrontEnd` state. Commit: `docs: record the front-end calls that start a game`.
2. **Front-end report.** Test whether the core mod can run Lua in the front end. If it can, print `FRONT_END <screen>` when the player moves between the main menu, the setup screen, and a game. This answers question 2. Commit: `feat(core): report the front-end screen`.
3. **Loading screen.** Test whether Lua can press the loading screen's button after `LOAD_READY` from step 4. This answers question 2. If it can, add the call to the core mod. Commit: `feat(core): start the game from the loading screen`.
4. **Preset files.** Add `packages/core/bridge/presets/smoke.yaml` and `mvp-gate.yaml` from the presets table, each with a fixed map seed. Check each file with a `zod` schema. Commit: `feat(core): add the test presets`.
5. **Launcher.** Add `npm run preset -- <name>`, which sets up the game from the preset file in the front-end state, starts it, and waits for `GAME_READY`. The core mod must be on in **Additional Content**. Check that before you start, and log a warning when it is off. Commit: `feat(core): start a test preset from the main menu`.

## Done when

From the main menu, `npm run preset -- smoke` starts a game that matches the smoke test row in [testing.md](../../design/testing.md#presets). Two runs give the same map.

## Record

- The front-end calls and the answers to questions 1 and 2, in [state-list.md](../../findings/state-list.md). Remove the answered questions.
- The preset files and the launcher, in [testing.md](../../design/testing.md#presets).
