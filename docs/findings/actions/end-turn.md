# Ending the turn

Status: open. Ending the turn, and the core mod's end turn action, are confirmed in a running game. How the end-turn blockers interact with it is open.

The game call the end turn action wraps, with the Lua state it runs in and where we found it. "Confirmed in files", "tested", and "used by civ6-mcp" mean what they mean in [game-api.md](../game-api.md).

The core mod's result format is in [design/core/mod/actions/README.md](../../design/core/mod/actions/README.md).

## Questions

1. Does the wonder built popup stop requests or the end turn call while it is open?

   `Base/Assets/UI/Popups/WonderBuiltPopup.lua` shows it for the local player only, from `Events.WonderCompleted`, and sets the `CINEMATIC` interface mode until the player presses **Close**. It is not an end-turn blocker.

   Can the mod skip it for an agent player, and do the other local-player cinematics, such as the natural wonder and era popups, need the same?

## What we know now

### Ending the turn

`UI.RequestAction(ActionTypes.ACTION_ENDTURN)` ends the turn. It's in `Base/Assets/UI/ActionPanel.lua` at line 512. The base UI calls it in five places. Confirmed in files.

Sent from `SentientSystemsCore_UI` in single player, it ended the turn, and the next `AGENT_TURN` line came 3 s later. Confirmed on Windows on 2026-10-23.

An end-turn blocker doesn't stop the request. `NotificationManager.GetFirstEndTurnBlocking(Game.GetLocalPlayer())` returned `ENDTURN_BLOCKING_RESEARCH`, the **Choose Research** prompt, before and after the turn ended.

`UI.CanEndTurn()` returned `true` with the blocker in place. Confirmed on Windows on 2026-10-23. The base UI checks the blocker itself before it calls `RequestAction`.

`DoEndTurn` in `ActionPanel.lua` ends the turn only when the blocker is `NO_ENDTURN_BLOCKING`. For any other blocker, it selects the next unit or opens the blocking notification. `DoEndTurn` starts at line 526. Confirmed in files.

civ6-mcp ends the turn with the same call, in [`build_end_turn`](https://github.com/lmwilki/civ6-mcp/blob/dd2019056371b92ea4854e879ddf05a8cad95e8a/src/civ_mcp/lua/notifications.py#L46). It never sends a second request while the first is still in progress, because a repeated request can skip turns.

Instead, it waits for the turn number to change. See [`end_turn.py`](https://github.com/lmwilki/civ6-mcp/blob/dd2019056371b92ea4854e879ddf05a8cad95e8a/src/civ_mcp/end_turn.py#L1139). Unconfirmed, used by civ6-mcp.

### The end turn action

`SentientSystems_EndTurn` sends the same request from `SentientSystemsCore_UI`. See [design/core/mod/actions/turn.md](../../design/core/mod/actions/turn.md).

On turn 53, with one unit that needed orders and no other blocker, the call without `force` returned that unit as the reason. With `force`, it ended the turn. A third call in the same turn was refused, and turn 54 began more than 15 s later. Confirmed on Windows on 2026-11-11.

On turn 54, the call without `force` named the great person and production blockers, with their choices, and 30 units that needed orders. The game also listed `ENDTURN_BLOCKING_UNITS`, which the reason leaves out. Confirmed on Windows on 2026-11-11.

## Method

Run each step through the tuner, and record the Lua state you ran it in.

1. **End the turn.** Run `UI.RequestAction(ActionTypes.ACTION_ENDTURN)`, and check that the next `AGENT_TURN` line arrives.
2. **Run the action.** With a blocker left, call `endTurn` from `packages/core/bridge/src/actions/turn.ts` without `force`, then with `force`, then with `force` again. Check the reason, the end of the turn, and the refusal.

## Results

The bridge ran this step in a single-player game, with one city and one unit.

| Call | Lua state | Result | Date |
| --- | --- | --- | --- |
| `Game.GetCurrentGameTurn()`, `UI.CanEndTurn()`, and `GetFirstEndTurnBlocking` | `SentientSystemsCore_UI` | Turn 1, `true`, and `ENDTURN_BLOCKING_RESEARCH` | 2026-10-23 |
| `SentientSystems_EndTurn(0, false)`, then `(0, true)` twice, on turn 53 | `SentientSystemsCore_UI` | The unit that needed orders as the reason, then `{"ok":true}`, then "You already ended turn 53." Turn 54 began | 2026-11-11 |
| `SentientSystems_EndTurn(0, false)` on turn 54 | `SentientSystemsCore_UI` | The great person and production blockers and 30 units as the reason | 2026-11-11 |
| `UI.RequestAction(ActionTypes.ACTION_ENDTURN)` | `SentientSystemsCore_UI` | The turn ended. `AGENT_TURN 0` came 3 s later, and the same three calls returned turn 2, `true`, and `ENDTURN_BLOCKING_RESEARCH` | 2026-10-23 |

Date checked: game files on 2026-10-16 and 2026-10-23. Running game on Windows: the end turn on 2026-10-23, and the end turn action on 2026-11-11.
