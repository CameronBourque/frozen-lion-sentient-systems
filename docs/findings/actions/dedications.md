# Dedication action

Status: confirmed. Making the dedication of a golden age, and the three of a heroic age, are confirmed in a running game with Gathering Storm, with the files sent through the tuner.

The game call that the dedication action wraps, with the Lua state it runs in and what the game checks. The dedications each age offers are in [choices/dedications.md](../choices/dedications.md).

The core mod's result format is in [design/core/mod/actions/README.md](../../design/core/mod/actions/README.md). The other actions are in the [actions index](README.md).

## Questions

None open.

## What we know now

### Request

`OnConfirm` in `DLC/Expansion2/UI/Additions/DedicationPopup.lua` closes the popup and sends one `UI.RequestPlayerOperation(Game.GetLocalPlayer(), PlayerOperations.COMMEMORATE, parameters)` for each dedication the player picked.

It sends the row's index in `GameInfo.CommemorationTypes` in `PARAM_COMMEMORATION_TYPE`.

**Confirm** is off until the player has picked `GetPlayerNumAllowedCommemorations(playerID)` of them, so the action asks for that many. Confirmed in files.

### What the request does

In `SentientSystemsCore_UI`, within 3 seconds of the requests, `ENDTURN_BLOCKING_COMMEMORATION_AVAILABLE` was gone and `Game.GetEras():GetPlayerActiveCommemorations(0)` held each dedication, in the order sent. The three requests of a heroic age all took. Confirmed on Windows on 2026-11-11.

## Method

1. Send `Scripts/SentientSystemsCore_Eras.lua`, the choice file, `Scripts/Choices/SentientSystemsCore_Choices.lua`, and `Scripts/Actions/SentientSystemsCore_ActionsDedications.lua` to `SentientSystemsCore_UI`, each without its comments and `include` lines.

   Do so as in [choices/production.md](../choices/production.md#method), step 4.
2. Load a save with `ENDTURN_BLOCKING_COMMEMORATION_AVAILABLE` up. To reach one, see [choices/dedications.md](../choices/dedications.md#method).
3. Call `chooseDedications` from the bridge, wait 3 seconds, and read the blockers and `GetPlayerActiveCommemorations(0)`.

## Results

A single-player game with Gathering Storm, in `SentientSystemsCore_UI`. A golden age at the Classical Era, on turn 199, with 1 pick from four dedications:

| Call | Result |
| --- | --- |
| `chooseDedications` with Free Inquiry and Pen, Brush, and Voice | `Choose 1 dedication, not 2.` |
| `chooseDedications` with `COMMEMORATION_MILITARY` | `COMMEMORATION_MILITARY isn't a dedication you can make. Use one of COMMEMORATION_SCIENTIFIC, COMMEMORATION_CULTURAL, COMMEMORATION_INFRASTRUCTURE, COMMEMORATION_RELIGIOUS.` |
| `chooseDedications` with `COMMEMORATION_SCIENTIFIC` | `{"ok":true}`. The blocker cleared, and it was the active dedication |
| `SentientSystems_ChooseDedications` again | `You have no dedication to make. The dedications choice lists one when an era begins.` |

A heroic age at the Medieval Era of another save, on turn 389, with 3 picks from the same four:

| Call | Result |
| --- | --- |
| `chooseDedications` with two | `Choose 3 dedications, not 2.` |
| `chooseDedications` with `COMMEMORATION_SCIENTIFIC` twice | `You chose COMMEMORATION_SCIENTIFIC twice. Choose each dedication once.` |
| `chooseDedications` with religious, scientific, and infrastructure | `{"ok":true}`. The blocker cleared, and the three were active, in that order |

Date checked: game files on 2026-11-11. Running game on Windows on 2026-11-11.
