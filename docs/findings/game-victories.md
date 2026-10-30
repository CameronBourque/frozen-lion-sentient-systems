# Game victories

Status: open. The `victories` section of `SentientSystems_GetState`, the progress toward each victory in the order of the Overall tab of World Rankings, is confirmed in a game with Gathering Storm on turn 403 with 20 players: the order of all five victories and the tooltips match the Overall tab. The Science tab's stages and tasks match the tab's tooltips with one stage done. The Culture, Domination, Religion, and Diplomacy tabs' details are in the state and read on a second save, where the numbers match the screenshots. The light years bar and the details of a team game have not been compared.

The calls the victories use, as the Overall tab in `WorldRankings.lua` and its Gathering Storm replacement, `WorldRankings_Expansion2.lua`, show them. See [in-game-lua.md](../design/core/in-game-lua.md).

## Questions

1. Does `Game.GetVictoryProgressForTeam` rise as the screen's rings fill? It was 0 for science, culture, and religion, and 0.083 for domination on a save at turn 3, and 0 to 0.15 on the turn 403 save.
2. Does the light years bar match the Science tab? The state read 4 of 150 at 4 per turn once the expedition was launched, and the tab was not open at the time.
3. How are the teams of a team game listed? The tab ranks teams, and the state lists each player with their own numbers.
4. Does it matter that the Culture, Domination, and Religion tabs order players differently from the Overall tab? They sort by tourists over the number required, captured capitals, and civs converted. The state keeps the Overall order for every victory.

## What we know now

### Overall tab

- **Victories.** `ViewOverall`, lines 608 to 647, lists science, culture, domination, and religion when `Game.IsVictoryEnabled` is true for `VICTORY_TECHNOLOGY`, `VICTORY_CULTURE`, `VICTORY_CONQUEST`, and `VICTORY_RELIGIOUS`, and then the custom victories. Gathering Storm adds `VICTORY_DIPLOMATIC` to `g_victoryData`, which the Diplomacy tab and the Overall tab use. `GameInfo.Victories` also has `VICTORY_SCORE` and `VICTORY_DEFAULT`, which have no ranking.
- **Order.** `PopulateOverallInstance`, lines 649 to 877, ranks the teams that `Game.GetVictoryProgressForTeam(victoryType, teamID)` answers for, since it answers nil for a team that can't win, such as a city-state. It sorts by that progress, then by the two tooltip numbers, then by the highest `GetScore()`, then by the lower team ID.
- **The tooltip numbers.** `g_victoryData`, lines 24 to 66: techs researched and science per turn for science, tourism and culture per turn for culture, military strength without the treasury for domination, cities following the player's religion and faith per turn for religion, and the diplomatic points of `GlobalParameters.DIPLOMATIC_VICTORY_POINTS_REQUIRED` for the diplomatic victory. The tooltip rounds to the tenth, and leaves out the second line when it equals the first.
- **Unmet players.** `PopulateOverallPlayerIconInstance` gives an icon the leader tooltip, which for a player that hasn't been met has no name or numbers. The state gives such a player `unmet`, no ID, and only the keys that the victory's own tab shows for every player, which the tab sections below list.
- **Progress.** The ring of each icon is filled to `TeamScore`, the progress from 0 to 1. The state rounds it to the nearest thousandth, since the game's float comes back as `0.10000000149`.

### Science tab

- **Stages.** `PopulateScienceInstance`, in `WorldRankings.lua` lines 1430 to 1510 and `WorldRankings_Expansion2.lua` lines 437 to 532, adds each of the player's cities' build queue values for the stage's projects. The base game has three stages, Earth satellite, Moon landing, and Mars colony, which has three projects: `PROJECT_LAUNCH_MARS_REACTOR`, `PROJECT_LAUNCH_MARS_HABITATION`, and `PROJECT_LAUNCH_MARS_HYDROPONICS`. Gathering Storm has four, each of one project: `PROJECT_LAUNCH_EARTH_SATELLITE`, `PROJECT_LAUNCH_MOON_LANDING`, `PROJECT_LAUNCH_MARS_BASE`, and `PROJECT_LAUNCH_EXOPLANET_EXPEDITION`.
- **Progress.** A project counts as its cost when `GetNumProjectsAdvanced` is above 0, and as `GetProjectProgress` otherwise. A bar fills with the progress over the total cost. The first two stages count only a city that has some progress, and the others count every city. A stage is marked when the total isn't 0 and the progress equals it, as the checkbox shows.
- **Tasks.** `GetTooltipForScienceProject` lists, for the first stage, a finished Spaceport (`DISTRICT_SPACEPORT`), and for each project, the tech in the row's `PrereqTech`, checked with `HasTech`, and the project. A project is checked from the last city's value, as the screen's loop leaves it.
- **Light years.** With Gathering Storm, a fifth stage lights up once the fourth is done. Its bar is `GetScienceVictoryPoints` over `GetScienceVictoryPointsTotalNeeded`, and its tooltip has `GetScienceVictoryPointsPerTurn`. The screen reads the total from the local player and clamps the light years to it, and the state does the same.

### Culture tab

- **Tourists.** `GatherCultureData`, in `WorldRankings.lua` lines 1656 to 1714, reads `GetStaycationers` (the domestic tourists) and `GetTouristsTo` (the visiting tourists). The tourists needed are one more than the most domestic tourists of any player on another team. For the viewing player that was 4, since the most among the others is 3, and for each other player it was 3020, the viewing player's 3019 plus one. Every player's row shows them, including one that hasn't been met.
- **Visitors from you.** `GetTouristsFrom` and `GetTouristsFromTooltip` of the viewing player, for each other player, give the number and the tooltip of the icon, which show for every player too. The state's `tourismBreakdown` is the tooltip's lines without icons, such as `Tourism: 73 (current)` and `Overall Tourism Reduced 0% for Different Governments`. It is the game's English text, as no call gives the parts.
- **Turns and dominance.** `GetTurnsUntilVictory` is -1 when no player is on course. `IsDominantOver` gives who is culturally dominant over whom, which `GetCulturalVictoryAdditionalSummary` in `WorldRankings_Expansion2.lua` shows as the counts of civs the player dominates and that dominate them, and for another player whether you or they dominate. The state gives these only for a player that has been met.

### Domination tab

- **Capitals.** `ViewDomination`, lines 1812 to 1882, lists a player only if `GetCapitalCity` isn't nil, and walks `GetCities():Members()` for cities whose `IsOriginalCapital` is true and whose `GetOriginalOwner` is a major player. The player has their own original capital when the owner is themselves and has captured it otherwise.
- **Unmet owners.** A captured capital of a player that hasn't been met shows as a question mark. The state counts it in `capitalsCaptured` and leaves its owner out of `capturedCapitals`. The row of a player that hasn't been met shows the same count, the original capital marker, and the icons of the captured capitals.

### Religion tab

- **Religions.** `GatherReligionData`, lines 2011 to 2082, takes `GetReligionTypeCreated` of each player, which is -1 when they founded none, and the tab lists only those with a religion. The civs converted are those whose `GetReligionInMajorityOfCities` is that religion, and the tab shows them as icons out of the number of living major players.
- **Unmet civs.** A converted civ that hasn't been met shows as a question mark. The state counts it in `civsConverted` and leaves it out of `convertedCivs`. The second save had none.

### Diplomacy tab

- **Points.** `ViewDiplomatic` lists the requirement text, `Diplomatic Points: 2/20`, for every player, and sets `GetDiplomaticVictoryPointsTooltip` as the tooltip of each row, which also shows for a player that hasn't been met. The state gives `points` and `required` from the requirement and the tooltip's lines as `breakdown`, such as `2 from Congress Participation`.

## Method

1. Send `SentientSystemsCore_StateVictories.lua` through the tuner as in [game-choices.md](game-choices.md#method), step 6, then `print(SentientSystems_EncodeJson(SentientSystems_GetVictoryState(Players[Game.GetLocalPlayer()])))`.
2. Open World Rankings, **Overall**, and compare the order of the icons of each victory and each tooltip with the state's.
3. For the Science tab, send `SentientSystemsCore_StateVictoriesScience.lua` first, then `print(SentientSystems_EncodeJson(SentientSystems_GetVictoryState(Players[Game.GetLocalPlayer()]).science[1].stages))`, and compare each bar and tooltip. To start a stage with the tuner, send `Players[0]:GetTechs():SetTech(GameInfo.Technologies["TECH_ROCKETRY"].Index, true)` to `GameCore_Tuner`, and end the turn for the UI state to see it. `Players[0]:GetStats():ChangeScienceVictoryPoints(n)` in `GameCore_Tuner` changes the light years.
4. For the other tabs, send `SentientSystemsCore_StateVictoriesCulture.lua`, `Domination`, and `Religion` first, then `SentientSystemsCore_StateVictories.lua` without its `SentientSystems_Include` lines, and compare each row of the Culture, Domination, Religion, and Diplomacy tabs, and each tooltip, with the state's keys.

## Results

A single-player game with Gathering Storm, on turn 403 with 20 players, in `SentientSystemsCore_State`:

| Check | Result |
| --- | --- |
| The section on the save | Science, culture, domination, religion, and diplomatic each listed 18 players, 11 of them the player and players they had met, with their numbers, and 7 as `unmet`. Diplomatic gave the met players 2 points of 20, and the player 1 |
| The Overall tab's icons for each victory, in order | Science, culture, domination, religion, and diplomatic matched the screen icon for icon, including where the unmet players sit, with the player first or, for diplomatic, last at 1 point and Zulu first at 2 |
| The tooltips | Technologies researched 1 and science per turn 3.5, tourism 0 and culture per turn 1.9, military strength 7, faith per turn 0 with 0 converted cities, and diplomatic points 2/20 matched the state's numbers for those civs |
| The Science tab with all techs researched and the first stage done | Stage 1 had the Spaceport, Rocketry, and the Earth satellite launch checked, and stages 2 to 4 had their tech checked and their launch open, as the tooltips showed. A launch is called Mars colony on the tab, and `PROJECT_LAUNCH_MARS_BASE` in the state |
| The Culture tab | The player had 3019 domestic tourists, and needed 4. The others had 0 to 3 and needed 3020, and the tooltip lines for a player that hasn't been met matched the screen |
| The Domination tab | The player held 2 captured capitals, `capturedCapitals` of 5 and 8, which the tab showed as two icons, and every player with a capital had its original capital marker |
| The Religion tab | The player's Buddhism had converted 4 of 18 civs, the player and civs 7, 9, and 12, which the tab showed as 4 icons |
| The Diplomacy tab | Every player had 2 of 20 points, with `1 from Wonders, Techs, and Civics` and `1 from Congress Participation` for the player, and `2 from Congress Participation` for the others, unmet players included |

Date checked: game files and a running game on Windows on 2026-10-30.
