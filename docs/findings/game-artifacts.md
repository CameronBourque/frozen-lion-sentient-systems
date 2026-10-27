# Game artifacts

Status: open. The `artifacts` key of `SentientSystems_GetChoices`, whose artifact the player's archaeologist uncovers, is confirmed in a running game with Gathering Storm and matches the artifact screen, for a tribal village and a battlefield.

The calls the artifact choice uses, as the artifact screen shows them. The other choices are in [game-choices.md](game-choices.md). See [in-game-lua.md](../design/core/in-game-lua.md).

## Questions

None open.

## What we know now

### Artifact screen

`Base/Assets/UI/Popups/ChooseArtifact.lua` draws the artifact screen, and no expansion replaces it. `NotificationPanel.lua` opens it from the `ENDTURN_BLOCKING_ARTIFACT` notification. Confirmed in files.

- **Artifact.** `OnOpen`, lines 4 to 77, reads the player's `GetUnits():GetNextExtractingArchaeologist()`, then `Game.GetArtifactByIndex(archaeologist:GetArchaeology():GetArtifactIndex())`, a table with `Type`, `ActingPlayerID`, `TargetPlayerID`, `ActingPlayerEra`, an index in `GameInfo.Eras`, and `TargetPlayerEra`. The era line names the acting player's era, which isn't the era of the game: a battlefield on turn 48 read "Industrial Era". Confirmed in files and on Windows on 2026-10-27.
- **Choice.** `Type` decides it, not the era. A tribal village, 1, a barbarian camp, 2, and a heroic relic, 5, have one player and an **OK** button, with no target, `TargetPlayerID` -1. A battle, 3, a sunk ship, 4, and a site of no type, 0, offer the acting and the target player as buttons. Each button sends `PlayerOperations.CHOOSE_ARTIFACT_PLAYER` with the player in `PARAM_PLAYER_ONE`, and **OK** sends the acting player. Confirmed in files and on Windows on 2026-10-27.
- **Text.** The explanation is `LOC_CHOOSE_ARTIFACT_EXPLANATION_` and the site's kind, such as `BATTLE_FOUGHT`, with the archaeologist's name and the players' `GetPlayerName()`, their leaders' names, such as Trajan and Free Cities. Confirmed in files and on Windows on 2026-10-27.
- **Blocker first.** The choice reads the archaeologist only while `ENDTURN_BLOCKING_ARTIFACT` is up, as the screen does, because a `GetNext` call with nothing waiting crashed the game for spies. See [game-spies.md](game-spies.md). Confirmed in files.

## Method

1. To find an artifact, give the player Natural History in `GameCore_Tuner` with `Players[0]:GetCulture():SetCivic(GameInfo.Civics["CIVIC_NATURAL_HISTORY"].Index, true)`. Training an archaeologist also needs an Archaeological Museum, `BUILDING_MUSEUM_ARTIFACT`, in the city. Then dig at an antiquity site.

## Results

A single-player game with Gathering Storm, on turn 48, in `SentientSystemsCore_UI`:

| Check | Result |
| --- | --- |
| The choices with Remo at a tribal village | Site type 1 from Trajan, player 0, in the Ancient Era, with one option. The screen read "Your Archaeologist Remo has uncovered signs of an ancient tribal village encountered by Trajan." with **OK**. `ENDTURN_BLOCKING_ARTIFACT` with `"choice":"artifacts"` |
| The choices on a reload, with Remo at a battlefield | `[{"archaeologist":2686995,"description":"Your Archaeologist Remo has discovered an ancient battlefield littered with items from Trajan and Free Cities.","era":"ERA_INDUSTRIAL","name":"Remo","options":[{"name":"Trajan","player":0},{"name":"Free Cities","player":62}],"x":48,"y":25}]`. The screen showed the same text, the Industrial Era, and **Trajan** and **Free Cities** |
| The choices through the bridge's readers | Parsed, with the same values |

Date checked: game files on 2026-10-27. Running game on Windows on 2026-10-27.
