# Game governors

Status: open. The `governors` section of `SentientSystems_GetState`, the player's governor titles and appointed governors, and the `governors` key of `SentientSystems_GetChoices`, the governors to appoint, the promotions to give, and the cities to assign them to, are confirmed in a running game with Gathering Storm, with the files sent through the tuner. The state matches the Governors panel. The choice matches the panel and the assignment chooser's list for a governor with no city, and hasn't been compared with the details panel. The promotion tree and Secret Societies come later in this task.

The calls the governors in the state and the governor choice use, as the Governors panel and its screens show them. The other choices are in [game-choices.md](game-choices.md). See [in-game-lua.md](../design/core/in-game-lua.md).

## Questions

1. Does the assignment chooser leave out the city a governor is already in, as the choice does?
2. How do Secret Societies' governors, which `GovernorsCannotAssign` marks, and their hidden promotions read in the state?

## What we know now

### Governors panel

Rise and Fall adds `DLC/Expansion1/UI/Additions/GovernorPanel.lua`, with `GovernorSupport.lua`, `GovernorDetailsPanel.lua`, and `GovernorAssignmentChooser.lua`, and Gathering Storm has its own copies in `DLC/Expansion2/UI/Additions`. A player has `GetGovernors()` only with Rise and Fall. All four `ENDTURN_BLOCKING_GOVERNOR_` blockers open the panel. Confirmed in files.

- **Titles.** `Refresh`, lines 39 to 122, shows `GetGovernorPoints()` less `GetGovernorPointsSpent()` as the titles available, and the titles spent. On turn 48 they were 1 and 8. Closing the panel calls `SetTitleConsidered(true)`, which cleared `ENDTURN_BLOCKING_GOVERNOR_OPPORTUNITY` with the title still unspent. Confirmed in files and on Windows on 2026-10-27.
- **Appointed governors.** `GetGovernorList()` returns whether there are any, and the list, in the panel's order. Each has `GetType()`, an index in `GameInfo.Governors`, whose row has `Name`, `Title`, and `Hash`. `GetGovernorStatus` in `GovernorSupport.lua`, lines 72 to 95, reads `GetNeutralizedTurns()`, `GetAssignedCity()`, `IsEstablished()`, and `GetTurnsToEstablish()` less `GetTurnsOnSite()`, the turns until a governor settles in. Pingala was established in Rome, Magnus in Ravenna, and Reyna in Ostia. Confirmed in files and on Windows on 2026-10-27.
- **Promotions.** `AddGovernorAppointed`, lines 359 to 434, lists each row of `GameInfo.GovernorPromotionSets()` for the governor's type, and marks those for which `HasPromotion(promotionHash)` is `true`. A set can hold another governor's promotion, such as Pingala's `GOVERNOR_PROMOTION_MERCHANT_CURATOR`. Pingala had 4, Magnus 3, and Reyna 1. Confirmed in files and on Windows on 2026-10-27.
- **Loyalty pressure.** The panel shows the governor row's `IdentityPressure`, 8 for each, and `GetTurnsToEstablish(hash)` on the player's governors, 3 for Victor and 5 for the rest. The assignment chooser shows an appointed governor's own `GetIdentityPressure()`, which promotions can raise, so the state uses it. Each of the three was 8. Confirmed in files and on Windows on 2026-10-27.
- **Appointing.** `AddGovernorCandidate`, lines 198 to 242, shows each governor for which `HasGovernor(hash)` is `false` and `CanEverAppointGovernor(hash)` is `true`, with the card's `GetTurnsToEstablish(hash)` and the row's `IdentityPressure`, and turns **Appoint** on when `CanAppoint()` is `true` and the screen isn't read-only. Appointing sends `PlayerOperations.APPOINT_GOVERNOR` with the governor's index in `PARAM_GOVERNOR_TYPE`. With 1 title, Victor, Amani, Moksha, and Liang could be appointed, and Ibrahim never could. After Amani was appointed, `CanAppoint()` was `false` and the choice had no `appoint`. `GovernorDetailsPanel.lua`, lines 48 to 148, shows each candidate's `Description`. Confirmed in files and on Windows on 2026-10-27.
- **Promoting.** `CreatePromotionTree`, lines 150 to 230, lists each promotion of the governor's `GovernorPromotionSets()`, and turns a button on when `CanEarnPromotion(governorHash, promotionHash)` is `true` and the governor doesn't have it, and the screen isn't read-only. The panel shows **Promote** for a governor for whom `CanPromoteGovernor(hash)` is `true`. Promoting sends `PROMOTE_GOVERNOR` with `PARAM_GOVERNOR_TYPE` and `PARAM_GOVERNOR_PROMOTION_TYPE`, the promotion's index. With 1 title, Pingala could earn Curator and Space Initiative, Magnus Industrialist and Black Marketeer, and Reyna Harbormaster and Forestry Management. Vertical Integration, Tax Collector, Renewable Subsidizer, and Contractor couldn't be earned yet. Confirmed in files and on Windows on 2026-10-27.
- **Assigning.** `RefreshBottomPanel` in `GovernorAssignmentChooser.lua`, lines 153 to 226, lists each of the player's cities, then for a governor with `IsGovernCityState()` the cities of each city-state the player has met, and for one with `CanAssignToMajorCiv()` the capital of each player they have met, and `AddCityInstance`, lines 228 to 262, leaves out the city the governor is in. A city-state's city or a capital is turned off, with the reasons, when `CanAssignGovernor(hash, city, true)` returns `false` and a table with the reasons in `PlayerOperationResults.FAILURE_REASONS`. The player's own cities are never turned off. Assigning sends `ASSIGN_GOVERNOR` with `PARAM_GOVERNOR_TYPE`, `PARAM_PLAYER_ONE`, the city's owner, and `PARAM_CITY_DEST`, its ID. A neutralized governor's **Assign** button is off. Pingala got the 8 cities but Rome, and Amani, with no city, the 9 cities and the cities of the 8 city-states met, with none turned off. Confirmed in files and on Windows on 2026-10-27.
- **Printing the tree.** The first attempts to read the tree crashed the game with an access violation, three times. The game's log reads printed text as a printf format, and a `% s` in a promotion's description made it read a pointer that was never passed. See [tuner-commands.md](tuner-commands.md#what-we-know-now). The JSON encoder now writes `%` as `\u0025`. Confirmed on Windows on 2026-10-27.
- **Read-only.** With Gathering Storm, `IsReadOnly` is `true` while the World Congress is in session, and every button is off. Confirmed in files.
- **Blocker.** These calls, unlike a `GetNext` call for a spy, read the same with `ENDTURN_BLOCKING_GOVERNOR_OPPORTUNITY` up and after `SetTitleConsidered(true)` cleared it, and didn't crash the game, as the launch bar opens the panel any turn. Confirmed on Windows on 2026-10-27.

## Method

1. To read a state section that the `.modinfo` doesn't load yet, send the code as in [game-choices.md](game-choices.md#method), step 6, and send `SentientSystemsCore_State.lua` again so it calls it.
2. Opening the Governors panel and closing it clears the governor blocker, so reload the save to see it again. `Players[0]:GetGovernors():SetTitleConsidered(true)` clears it from the UI state.
3. To appoint a governor without the panel, send `UI.RequestPlayerOperation(0, PlayerOperations.APPOINT_GOVERNOR, params)` in `SentientSystemsCore_UI`, with the governor's index in `params[PlayerOperations.PARAM_GOVERNOR_TYPE]`. It spends the title.

## Results

A single-player game with Gathering Storm, on turn 48, in `SentientSystemsCore_UI`:

| Check | Result |
| --- | --- |
| The state with three governors appointed | 1 title and 8 spent. Pingala in Rome, Magnus in Ravenna, and Reyna in Ostia, each established, with loyalty 8 and 5 turns to establish, and 4, 3, and 1 promotions. The panel showed **Governor titles available: 1**, **Spent: 8**, the same governors, cities, and earned promotions, and Victor, Amani, Moksha, and Liang as candidates |
| The state through the bridge's readers | Parsed, with the same values |
| The choices on the same turn | `appoint` with Victor, Amani, Moksha, and Liang, each with loyalty 8 and 3 or 5 turns to establish. `promote` with 2 promotions each for Pingala, Magnus, and Reyna. `assign` with 8 cities each, 3,709 bytes. The same after the blocker was cleared, through the bridge's readers |
| The choices after appointing Amani | No `appoint`, as all 9 titles were spent. Amani's `assign` with the 9 cities and 8 city-state cities, 744 bytes |
| The Governors panel after appointing Amani | **Governor titles available: 0** and **Spent: 9**. Amani on **Needs Assignment** with a green **Assign** button, and **Appoint** turned off for Victor, Moksha, and Liang, as the choice has it. The assignment chooser's list wasn't shown |
| The assignment chooser for Amani, who had no city | Rome, Antium, Lugdunum, Setia, Ravenna, Ostia, Arpinum, Arretium, and Stockholm, then the city-states Kumasi, Zanzibar, Bologna, Nalanda, Valletta, Hunza, Jerusalem, and Hong Kong, in the choice's order, none turned off. The card read **The Diplomat**, 5 turns and loyalty 8, and **Replaces: No Governor Assigned** once a city was picked, and **Assign** turned on |

Date checked: game files on 2026-10-27. Running game on Windows on 2026-10-27.
