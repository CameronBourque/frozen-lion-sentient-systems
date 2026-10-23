# Step 4: Load signal

Add two tagged lines from the core mod: one when the loading screen shows its button, and one when the game has loaded and commands work. On the second line, the bridge lists the states again, starts a new log file, and stops any agent turn from the old game. Part of [phase 1](README.md).

Both lines are tagged, so the bridge keeps its rule that it reads only tagged lines. See [bridge.md](../../design/core/bridge.md#decisions).

## Tasks

1. **Find the events.** In `<game>\Base\Assets\UI\LoadScreen.lua`, find which events fire when the button shows and when the player clicks it, such as `Events.LoadGameViewStateDone` and `Events.LoadScreenClose`. Add a temporary print in the core mod's UI script for each one, and run steps 4 and 5 of the [Lua state method](../../findings/lua-contexts.md#method). Record which print comes before the click, which comes after it, and when commands start to answer. This answers question 4. Commit: `docs: record when commands work after a load`.
2. **Button line.** Print `LOAD_READY` from the event that fires when the button shows. If the tuner holds the print until the click, record that, and keep the line for `Lua.log`. Commit: `feat(core): print LOAD_READY when the loading screen shows its button`.
3. **Game line.** Print `GAME_READY <turn>` from the event that fires after the click. Remove the other temporary prints. Commit: `feat(core): print GAME_READY when a load finishes`.
4. **Bridge.** Parse both lines in `src/events.ts`. On `LOAD_READY`, log that the game waits for the click. On `GAME_READY`, list the states again, start a new log file, and cancel any agent turn in progress. Test each with a fake client. Commit: `feat(core): reset the session on GAME_READY`.
5. **Docs.** Describe both lines in [in-game-lua.md](../../design/core/in-game-lua.md) and the reset in [bridge.md](../../design/core/bridge.md). Update the stale state list row in [risks.md](../../risks.md). Commit: `docs: describe the load signal`.

## Done when

Load a save, quit to the main menu, and load it again. At each loading screen, the log shows `LOAD_READY`, or the finding says why it can't. After each click, the bridge logs `GAME_READY`, lists the states again, and the next command answers.

## Record

- The events, their order, and whether the tuner carries `LOAD_READY` before the click, in [lua-contexts.md](../../findings/lua-contexts.md#state-list-over-a-session). Remove question 4.
- Both lines, in [in-game-lua.md](../../design/core/in-game-lua.md), with a `## Decisions` row for tagged load lines.
- The reset, in [bridge.md](../../design/core/bridge.md).
