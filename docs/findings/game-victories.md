# Game victories

Status: open. The `victories` section of `SentientSystems_GetState`, the progress toward each victory in the order of the Overall tab of World Rankings, is confirmed in a game with Gathering Storm on turn 403 with 20 players: the order of all five victories and the tooltips match the Overall tab. The Science, Culture, Domination, Religion, and Diplomacy tabs' details are not in the state yet.

The calls the victories use, as the Overall tab in `WorldRankings.lua` and its Gathering Storm replacement, `WorldRankings_Expansion2.lua`, show them. See [in-game-lua.md](../design/core/in-game-lua.md).

## Questions

1. Does `Game.GetVictoryProgressForTeam` rise as the screen's rings fill? It was 0 for science, culture, and religion, and 0.083 for domination on a save at turn 3, and 0 to 0.15 on the turn 403 save.
2. How are the teams of a team game listed? The tab ranks teams, and the state lists each player with their own numbers.

## What we know now

### Overall tab

- **Victories.** `ViewOverall`, lines 608 to 647, lists science, culture, domination, and religion when `Game.IsVictoryEnabled` is true for `VICTORY_TECHNOLOGY`, `VICTORY_CULTURE`, `VICTORY_CONQUEST`, and `VICTORY_RELIGIOUS`, and then the custom victories. Gathering Storm adds `VICTORY_DIPLOMATIC` to `g_victoryData`, which the Diplomacy tab and the Overall tab use. `GameInfo.Victories` also has `VICTORY_SCORE` and `VICTORY_DEFAULT`, which have no ranking.
- **Order.** `PopulateOverallInstance`, lines 649 to 877, ranks the teams that `Game.GetVictoryProgressForTeam(victoryType, teamID)` answers for, since it answers nil for a team that can't win, such as a city-state. It sorts by that progress, then by the two tooltip numbers, then by the highest `GetScore()`, then by the lower team ID.
- **The tooltip numbers.** `g_victoryData`, lines 24 to 66: techs researched and science per turn for science, tourism and culture per turn for culture, military strength without the treasury for domination, cities following the player's religion and faith per turn for religion, and the diplomatic points of `GlobalParameters.DIPLOMATIC_VICTORY_POINTS_REQUIRED` for the diplomatic victory. The tooltip rounds to the tenth, and leaves out the second line when it equals the first.
- **Unmet players.** `PopulateOverallPlayerIconInstance` gives an icon the leader tooltip, which for a player that hasn't been met has no name or numbers. The state gives such a player only `unmet`.
- **Progress.** The ring of each icon is filled to `TeamScore`, the progress from 0 to 1. The state rounds it to the nearest thousandth, since the game's float comes back as `0.10000000149`.

## Method

1. Send `SentientSystemsCore_StateVictories.lua` through the tuner as in [game-choices.md](game-choices.md#method), step 6, then `print(SentientSystems_EncodeJson(SentientSystems_GetVictoryState(Players[Game.GetLocalPlayer()])))`.
2. Open World Rankings, **Overall**, and compare the order of the icons of each victory and each tooltip with the state's.

## Results

A single-player game with Gathering Storm, on turn 403 with 20 players, in `SentientSystemsCore_State`:

| Check | Result |
| --- | --- |
| The section on the save | Science, culture, domination, religion, and diplomatic each listed 18 players, 11 of them the player and players they had met, with their numbers, and 7 as `unmet`. Diplomatic gave the met players 2 points of 20, and the player 1 |
| The Overall tab's icons for each victory, in order | Science, culture, domination, religion, and diplomatic matched the screen icon for icon, including where the unmet players sit, with the player first or, for diplomatic, last at 1 point and Zulu first at 2 |
| The tooltips | Technologies researched 1 and science per turn 3.5, tourism 0 and culture per turn 1.9, military strength 7, faith per turn 0 with 0 converted cities, and diplomatic points 2/20 matched the state's numbers for those civs |

Date checked: game files and a running game on Windows on 2026-10-30.
