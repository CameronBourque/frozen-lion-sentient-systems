# Game religion

Status: open. The `pantheon` key of `SentientSystems_GetChoices`, the pantheon beliefs the player can found a pantheon with, is confirmed in a running game with Gathering Storm.

The calls the religion choices use, as the game's religion screens show them. The other choices are in [game-choices.md](game-choices.md). See [in-game-lua.md](../design/core/in-game-lua.md).

## Questions

None open.

## What we know now

### Pantheon

`Base/Assets/UI/Choosers/PantheonChooser.lua` draws the pantheon chooser. The expansions load the same file and don't replace it. Confirmed in files.

- **Opening.** `LaunchBar.lua`, lines 136 to 140, opens the chooser when `player:GetReligion():GetPantheon()` is below 0 and `CanCreatePantheon()` is `true`. `GetPantheon()` returns the index of the pantheon's belief in `GameInfo.Beliefs`, or -1 for none. With 100 faith added on turn 14, `CanCreatePantheon()` stayed `false` until turn 15. Confirmed in files and on Windows on 2026-10-26.
- **Beliefs.** `Realize`, lines 23 to 44, lists each row of `GameInfo.Beliefs()` that `CanSelectBelief`, lines 63 to 72, allows: its `BeliefClassType` is `BELIEF_CLASS_PANTHEON`, and `Game.GetReligion():IsInSomePantheon(index)` and `IsInSomeReligion(index)` are both `false`. Each card shows the belief's `Name` and `Description`. On turn 19 of a later save, `IsInSomePantheon` was `true` for Desert Folklore, Egypt's pantheon, and for Religious Settlements, the player's. Confirmed in files and on Windows on 2026-10-26.
- **Founding.** `ConfirmPantheon`, lines 120 to 131, sends `PlayerOperations.FOUND_PANTHEON` with the belief's hash in `PARAM_BELIEF_TYPE`. Confirmed in files.

## Method

1. To read a choice that the `.modinfo` doesn't load yet, send the code as in [game-choices.md](game-choices.md#method), step 6, then read `SentientSystems_GetChoices(Game.GetLocalPlayer())`.
2. To see the pantheon chooser, load a save from before a pantheon, send `Players[0]:GetReligion():ChangeFaithBalance(100)` in `GameCore_Tuner`, and end the turn.

## Results

A single-player game with Gathering Storm, on Rome's save, in `SentientSystemsCore_UI`:

| Check | Result |
| --- | --- |
| The choices on turn 14, with no pantheon and 100 faith from the tuner | No `pantheon` key, as `CanCreatePantheon()` was `false` |
| The choices on turn 15, with the same faith | 23 beliefs, from Dance of the Aurora to Fire Goddess, `BELIEF_GODDESS_OF_FIRE`, each with its description. No player had a pantheon yet. The chooser listed the same 23 in the same order, with the same text. `ENDTURN_BLOCKING_PANTHEON` was among the blockers. 3,046 bytes |

Date checked: game files on 2026-10-26. Running game on Windows on 2026-10-26.
