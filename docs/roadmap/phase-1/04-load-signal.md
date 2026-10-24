# Step 4: Load signal

Add two tagged lines from the core mod: one when the loading screen shows its button, and one when the game has loaded and commands work. On the second line, the bridge lists the states again and starts a new log file. Part of [phase 1](README.md).

Both lines are tagged, so the bridge keeps its rule that it reads only tagged lines. See [bridge.md](../../design/core/bridge.md#decisions).

The agent loop doesn't exist yet, so this step doesn't cancel an agent turn. [Step 14](14-agent-loop.md) cancels the turn on `GAME_READY`.

## What the game files show

`<game>\Base\Assets\UI\FrontEnd\LoadScreen.lua` handles the loading screen. Checked on 2026-10-23.

| Event | When it fires | Where |
| --- | --- | --- |
| `Events.LoadGameViewStateDone` | The game has loaded, and the screen shows its button. The handler prints `OnLoadGameViewStateDone` | `OnLoadGameViewStateDone`, line 457 |
| `Events.LoadScreenClose` | The player clicked the button. `OnActivateButtonClicked` fires it | Line 50 |

`OnLoadGameViewStateDone` clicks the button for the player in a resync load, in any multiplayer game, hotseat included, and in World Builder. It does the same when `Automation.IsAutoStartEnabled()` is true. In those games, both events fire one after the other.

## Tasks

1. **Find the order.** Add the temporary probes from step 7 of the [Lua state method](../../findings/lua-contexts.md#method), and run steps 5 and 7. Record which probe comes before the click, which comes after it, when commands start to answer, and whether the bridge gets the `LoadScreenClose` probe or loses it when the socket resets. This answers question 4. Don't commit the probes. Commit: `docs: record when commands work after a load`.
2. **Button line.** Print `LOAD_READY` from `Events.LoadGameViewStateDone`. If the tuner holds the print until the click, record that, and keep the line for `Lua.log`. Commit: `feat(core): print LOAD_READY when the loading screen shows its button`.
3. **Game line.** Print `GAME_READY <turn>` from `Events.LoadScreenClose`. Remove the probes. Commit: `feat(core): print GAME_READY when a load finishes`.
4. **Resync after a reset.** Do this task only if task 1 found that the bridge loses the `LoadScreenClose` probe. Set a flag in the `LoadScreenClose` handler, and make `SentientSystems_Resync()` print `GAME_READY <turn>` once the flag is set. The UI state is rebuilt for each game, so the flag starts false in each one. Commit: `feat(core): print GAME_READY again on resync`.
5. **Parse the lines.** Add `LOAD_READY` and `GAME_READY <turn>` to `src/events.ts`, with their log lines. `LOAD_READY` logs that the game waits for the click. Test each line and each bad form. Commit: `feat(core): parse the load lines`.
6. **Reset on `GAME_READY`.** On `GAME_READY`, the bridge lists the states again and starts a new log file. A reconnect no longer starts a new log file. Every `GAME_READY` resets, including one from a resync. A reconnect in the middle of a game is rare, and its only cost is an extra log file. Test with a fake client. Commit: `feat(core): reset the session on GAME_READY`.
7. **Docs.** Describe both lines in [in-game-lua.md](../../design/core/in-game-lua.md) and the reset in [bridge.md](../../design/core/bridge.md). Update the stale state list row in [risks.md](../../risks.md). Commit: `docs: describe the load signal`.

## Done when

Load a save, quit to the main menu, and load it again. At each loading screen, the log shows `LOAD_READY`, or the finding says why it can't. After each click, the bridge logs `GAME_READY`, lists the states again, starts a new log file, and the next command answers.

## Record

- The events, their order, whether the tuner carries `LOAD_READY` before the click, and whether `GAME_READY` survives the socket reset, in [lua-contexts.md](../../findings/lua-contexts.md#state-list-over-a-session). Remove question 4.
- The auto-click cases, in [lua-contexts.md](../../findings/lua-contexts.md#state-list-over-a-session), with a link from question 3.
- Both lines, in [in-game-lua.md](../../design/core/in-game-lua.md), with a `## Decisions` row for tagged load lines.
- The reset, in [bridge.md](../../design/core/bridge.md).
