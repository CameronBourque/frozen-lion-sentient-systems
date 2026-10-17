# Step 2: Turn on the tuner

Enable the tuner and check that FireTuner can run Lua in a live game. Part of [phase 0](README.md).

## Tasks

1. Turn on the tuner from the Options menu by following steps 1 to 3 of the [tuner setup method](../../findings/tuner-setup.md#method). If the menu has no **Tuner** toggle, set `EnableTuner 1` on line 75 of `AppOptions.txt` instead, as step 1 of the [tuner protocol method](../../findings/tuner-protocol.md#method) describes.
2. Optionally, set `EnableDebugMenu 1` on line 78 to turn on the game's debug menu.
3. Start Civ VI, and load or start a game with the smoke test preset from [design/testing.md](../../design/testing.md#presets).
4. Start `FireTuner2.exe` and connect it to the game. [findings/README.md](../../findings/README.md#local-paths) lists the paths.

## Done when

FireTuner shows the console and a list of Lua states, and `print("hello")` in the console shows output.

## Record

- The Lua state names FireTuner shows, in [lua-contexts.md](../../findings/lua-contexts.md#lua-state-list).
- Whether the menu toggle exists and writes the file, in [tuner-setup.md](../../findings/tuner-setup.md#results), question 1.
