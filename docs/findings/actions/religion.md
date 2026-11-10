# Religion actions

Status: confirmed. Founding a pantheon is confirmed in a running game with Gathering Storm.

The game calls that the pantheon and religion actions wrap, with the Lua state they run in and what the game checks. The beliefs and religions the player can pick are in [choices/religion.md](../choices/religion.md).

The core mod's result format is in [design/core/mod/actions/README.md](../../design/core/mod/actions/README.md). The other actions are in the [actions index](README.md).

## Questions

None open.

## What we know now

### Pantheon

`ConfirmPantheon` in `Base/Assets/UI/Choosers/PantheonChooser.lua` calls `UI.RequestPlayerOperation(Game.GetLocalPlayer(), PlayerOperations.FOUND_PANTHEON, parameters)`. The parameters hold the belief's hash in `PARAM_BELIEF_TYPE` and `VALUE_EXCLUSIVE` in `PARAM_INSERT_MODE`. Confirmed in files.

- The chooser checks nothing before its request, because it lists only the beliefs `CanSelectBelief` allows. Confirmed in files.
- `UI.CanStartPlayerOperation(playerID, PlayerOperations.FOUND_PANTHEON, parameters, testOnly)` returned `true` with no reasons for a pantheon belief and for a follower belief, with `testOnly` `true` and `false`. So the action checks the class itself. Confirmed on Windows on 2026-11-09.
- The request runs in `SentientSystemsCore_UI`. 1.5 seconds after it, `GetPantheon()` returned the belief's index, `CanCreatePantheon()` returned `false`, and the faith balance had dropped by `GetMinimumFaithNextPantheon()`. Confirmed on Windows on 2026-11-09.
- Once the pantheon is founded, `IsInSomePantheon` is `true` for its belief, and `ENDTURN_BLOCKING_PANTHEON` leaves the blockers. Confirmed on Windows on 2026-11-09.

## Method

1. To get the pantheon blocker, follow [choices/religion.md](../choices/religion.md#method), step 2.
2. Send `Scripts/SentientSystemsCore_Religion.lua`, then `Scripts/Actions/SentientSystemsCore_ActionsReligion.lua`, to `SentientSystemsCore_UI`, as in [choices/production.md](../choices/production.md#method), step 4.
3. Call `foundPantheon` from the bridge. Wait 1.5 seconds, then read `GetPantheon()`, `CanCreatePantheon()`, and `GetFaithBalance()` on `Players[0]:GetReligion()`.
4. To see what the game takes, call `UI.CanStartPlayerOperation` with the pantheon chooser's parameters and a belief of another class.

## Results

A single-player game with Gathering Storm, on Rome's save on turn 15, in `SentientSystemsCore_UI`, for player 0, with 1,004 faith and a pantheon cost of 12:

| Call | Result |
| --- | --- |
| `foundPantheon(BELIEF_NOPE)` | `BELIEF_NOPE isn't a belief.`, and a pointer to the choice |
| `foundPantheon(BELIEF_FEED_THE_WORLD)` | `BELIEF_FEED_THE_WORLD isn't a pantheon belief.`, and a pointer to the choice |
| `foundPantheon(BELIEF_RELIGIOUS_SETTLEMENTS)` | `{"ok":true}`. The pantheon became Religious Settlements, index 19, and the faith 992 |
| `foundPantheon(BELIEF_GOD_OF_THE_SEA)`, after that | `You have a pantheon already, BELIEF_RELIGIOUS_SETTLEMENTS.` |

After the pantheon, the state showed `"pantheon":"BELIEF_RELIGIOUS_SETTLEMENTS"`, and `ENDTURN_BLOCKING_UNITS` was the only blocker.

Date checked: 2026-11-09.
