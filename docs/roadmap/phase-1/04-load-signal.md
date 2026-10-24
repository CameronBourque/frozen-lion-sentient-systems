# Step 4: Load signal

Add two tagged lines from the core mod: one when the loading screen shows its button, and one when the game has loaded and commands work. On the first line, the bridge starts a new log file, so each game's file begins at its loading screen. On the second, it lists the states again. [Step 15](15-preset-launcher.md) can also use the first line to press the button from Lua. Part of [phase 1](README.md).

Both lines are tagged, so the bridge keeps its rule that it reads only tagged lines. See [bridge.md](../../design/core/bridge.md#decisions).

The agent loop doesn't exist yet, so this step doesn't cancel an agent turn. [Step 14](14-agent-loop.md) cancels the turn on `GAME_READY`.

## What the game files show

`<game>\Base\Assets\UI\FrontEnd\LoadScreen.lua` handles the loading screen. Checked on 2026-10-23.

| Event | When it fires | Where |
| --- | --- | --- |
| `Events.LoadGameViewStateDone` | The game has loaded, and the screen shows its button. The handler prints `OnLoadGameViewStateDone` | `OnLoadGameViewStateDone`, line 457 |
| `Events.LoadScreenClose` | The player clicked the button. `OnActivateButtonClicked` fires it | Line 50 |

Some games click the button for the player, and then both events fire one after the other. See the auto-click row in [state-list.md](../../findings/state-list.md#state-list-over-a-session).

The tests on 2026-10-23 found that the bridge gets both prints. The `LoadGameViewStateDone` print arrives as the button shows, and the `LoadScreenClose` print arrives before the socket resets at the click. `Game.GetCurrentGameTurn()` works in both handlers. So `GAME_READY` needs no resync.

## Tasks

1. **Find the order.** Add the temporary probes from step 4 of the [state list method](../../findings/state-list.md#method), and run steps 3 and 4. Record which probe comes before the click, which comes after it, when commands start to answer, and whether the bridge gets the `LoadScreenClose` probe or loses it when the socket resets. This answers question 4. Don't commit the probes. Commit: `docs: record when commands work after a load`.
2. **Button line.** Print `LOAD_READY` from `Events.LoadGameViewStateDone`. Commit: `feat(core): print LOAD_READY when the loading screen shows its button`.
3. **Game line.** Print `GAME_READY <turn>` from `Events.LoadScreenClose`. Remove the probes. Commit: `feat(core): print GAME_READY when a load finishes`.
4. **Parse the lines.** Add `LOAD_READY` and `GAME_READY <turn>` to `src/events.ts`, with their log lines. `LOAD_READY` logs that the game waits for the click. Test each line and each bad form. Commit: `feat(core): parse the load lines`.
5. **Reset on a load.** On `LOAD_READY`, the bridge starts a new log file. A quit to the main menu doesn't disconnect, so this keeps the new game's lines out of the old game's file. On `GAME_READY`, it lists the states again. A reconnect no longer starts a new log file. Test with a fake client. Commit: `feat(core): reset the session on each load`.
6. **Docs.** Describe both lines in [in-game-lua.md](../../design/core/in-game-lua.md), the reset in [bridge.md](../../design/core/bridge.md), and the log file in [logs.md](../../design/core/logs.md). Update the stale state list row in [risks.md](../../risks.md). Commit: `docs: describe the load signal`.

## Done when

Load a save, quit to the main menu, and load it again. At each loading screen, the bridge logs `LOAD_READY` as the first line of a new log file. After each click, it logs `GAME_READY`, lists the states again, and the next command answers.

## Record

- The events, their order, whether the tuner carries `LOAD_READY` before the click, and whether `GAME_READY` survives the socket reset, in [state-list.md](../../findings/state-list.md#state-list-over-a-session). Remove question 4.
- The auto-click cases, in [state-list.md](../../findings/state-list.md#state-list-over-a-session), with a link from question 2.
- Both lines, in [in-game-lua.md](../../design/core/in-game-lua.md), with a `## Decisions` row for tagged load lines.
- The reset, in [bridge.md](../../design/core/bridge.md).
- The log file for each load, in [logs.md](../../design/core/logs.md), with a `## Decisions` row for starting it on `LOAD_READY`.
