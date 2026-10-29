# Game scoreboard

Status: open. The `scoreboard` section of `SentientSystems_GetState`, the scores and the leader panel's numbers, is confirmed in a running game with Gathering Storm on turn 15, with the file sent through the tuner. It matches the Score tab of World Rankings, with its details, and the leader panel for two players that had met. The players they hadn't met, with their scores and categories and the tie order, are confirmed on a save at turn 3 with 12 players, one of them met. A favor above 0 is checked in the fake game only.

The calls the scoreboard uses, as the Score tab in `WorldRankings.lua` and the leader panel in `DiplomacyRibbon.lua` show them. See [in-game-lua.md](../design/core/in-game-lua.md).

## Questions

1. Does the leader panel's favor match `GetFavor` above 0? It was 0 for both players.
2. Do equal scores stay in ID order in the tab? `ViewScore` sorts with `table.sort`, which isn't stable. On the turn 3 save the three players with 9 matched the state's order, but it may differ on other saves.

## What we know now

### Score tab

- **Players.** `GatherScoreData`, lines 1073 to 1106, lists every living major player, from `GetAliveMajorTeamIDs`, with `GetScore()` and the details' categories, whether or not the player has met them. The icon of a player the player hasn't met is masked as "Unmet Player", and the numbers aren't. The state leaves out that player's ID. A team sorts by the sum of its scores, and the state lists players flat.
- **Categories.** The details toggle lists each row of `GameInfo.ScoringCategories`, indexed from 0, with a `Multiplier` above 0, and `GetCategoryScore(index)`. The game has 13 rows, and 7 have a multiplier: `CATEGORY_CIVICS`, `CATEGORY_EMPIRE`, `CATEGORY_GREAT_PEOPLE`, `CATEGORY_RELIGION`, `CATEGORY_TECH`, `CATEGORY_WONDER`, and `CATEGORY_ERA_SCORE`. Their names are `Civics`, `Empire`, `Great People`, `Religion`, `Technology`, `Wonders`, and `Era Score`. Iterating `GameInfo.ScoringCategories()` with `row.Index` finds them, as the other state files do.

### Leader panel

- **Players.** `UpdateLeaders` shows the player first, then each living major player they have met. A multiplayer human the player hasn't met shows masked.
- **Numbers.** `UpdateStatValues` shows the score, `GetMilitaryStrengthWithoutTreasury`, `GetScienceYield`, `GetCultureYield`, `GetGoldBalance`, and `GetFaithBalance`. Gold is rounded down and the rest to the nearest whole number. Science and culture are per turn, and gold and faith are balances.
- **Favor.** `DiplomacyRibbon_Expansion2.lua` adds `GetFavor`, rounded, when `Game.IsVictoryEnabled("VICTORY_DIPLOMATIC")`. Without Gathering Storm a player has no `GetFavorPerTurn`, which the state uses as the check, as the player section does.

## Method

1. Send `SentientSystemsCore_StateScoreboard.lua` through the tuner as in [game-choices.md](game-choices.md#method), step 6, then `print(SentientSystems_EncodeJson(SentientSystems_GetScoreboardState(Players[Game.GetLocalPlayer()])))`.
2. Open World Rankings, **Score**, turn on **Show Details**, and compare each number with the state's. Compare the leader panel's numbers at the top right.

## Results

A single-player game with Gathering Storm, on turn 15, in `SentientSystemsCore_State`, with two players that had met:

| Check | Result |
| --- | --- |
| The Score tab with its details | Scores 48 and 25. The first player had Civics 3, Empire 13, Great People 0, Religion 10, Technology 8, Wonders 0, and Era Score 14, and the second 3, 9, 0, 0, 4, 0, and 9, as the screen showed |
| The leader panel | Military 30 and 20, science 4 and 3, culture 4 and 4, gold 107 and 88, faith 591 and 6, and favor 0 and 0, as the panel showed |
| A save at turn 3 with 12 players, one of them met | The tab listed the players by score, 22, 13, 11, 10, 9, 9, and so on. The state's categories matched the details of the player (Empire 13, Era Score 9) and of an unmet player with 13 (Empire 7, Era Score 6). Only the player and the one met player had the leader panel's numbers |
| Rounding | The faith of 591 and the culture of 4 matched the panel |

Date checked: game files and a running game on Windows on 2026-10-30.
