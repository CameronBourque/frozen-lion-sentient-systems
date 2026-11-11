# Governor choices

Status: open. The `governors` key of `SentientSystems_GetChoices`, the governors to appoint, the promotions to give, and the cities to assign them to, is confirmed in a running game with Gathering Storm, with the files sent through the tuner.

The choice matches the panel and the assignment chooser's list for a governor with no city, and hasn't been compared with the details panel.

The calls the governor choice uses, as the Governors panel and its screens show them. The governor tree and the Secret Societies are in [choices/governor-tree.md](governor-tree.md).

The other choices are in the [choices index](README.md). See [design/core/mod/choices.md](../../design/core/mod/choices.md).

## Questions

1. Does the assignment chooser leave out the city a governor is already in, as the choice does?

## What we know now

### Governors panel

The panel's files, and the calls for the titles and the appointed governors, are in [state/governors.md](../state/governors.md#governors-panel).

- **Appointing.** `AddGovernorCandidate`, lines 198 to 242, shows each governor for which `HasGovernor(hash)` is `false` and `CanEverAppointGovernor(hash)` is `true`.

  It shows the card's `GetTurnsToEstablish(hash)` and the row's `IdentityPressure`, and turns **Appoint** on when `CanAppoint()` is `true` and the screen isn't read-only.

  The requests are in [actions/governors.md](../actions/governors.md#requests). With 1 title, Victor, Amani, Moksha, and Liang could be appointed, and Ibrahim never could.

  After Amani was appointed, `CanAppoint()` was `false` and the choice had no `appoint`. `GovernorDetailsPanel.lua`, lines 48 to 148, shows each candidate's `Description`. Confirmed in files and on Windows on 2026-10-27.
- **Promoting.** `CreatePromotionTree`, lines 150 to 230, lists each promotion of the governor's `GovernorPromotionSets()`, and turns a button on when `CanEarnPromotion(governorHash, promotionHash)` is `true` and the governor doesn't have it, and the screen isn't read-only.

  The panel shows **Promote** for a governor for whom `CanPromoteGovernor(hash)` is `true`.

  With 1 title, Pingala could earn Curator and Space Initiative, Magnus Industrialist and Black Marketeer, and Reyna Harbormaster and Forestry Management.

  Vertical Integration, Tax Collector, Renewable Subsidizer, and Contractor couldn't be earned yet. Confirmed in files and on Windows on 2026-10-27.
- **Assigning.** `RefreshBottomPanel` in `GovernorAssignmentChooser.lua`, lines 153 to 226, lists each of the player's cities.

  For a governor with `IsGovernCityState()`, it adds the cities of each city-state the player has met, and for one with `CanAssignToMajorCiv()`, the capital of each player they have met. `AddCityInstance`, lines 228 to 262, leaves out the city the governor is in.

  A city-state's city or a capital is turned off, with the reasons, when `CanAssignGovernor(hash, city, true)` returns `false` and a table with the reasons in `PlayerOperationResults.FAILURE_REASONS`.

  The player's own cities are never turned off. A neutralized governor's **Assign** button is off.

  Pingala got the 8 cities but Rome, and Amani, with no city, the 9 cities and the cities of the 8 city-states met, with none turned off. Confirmed in files and on Windows on 2026-10-27.
- **Read-only.** With Gathering Storm, `IsReadOnly` is `true` while the World Congress is in session, and every button is off. Confirmed in files.
- **Blocker.** These calls, unlike a `GetNext` call for a spy, read the same with `ENDTURN_BLOCKING_GOVERNOR_OPPORTUNITY` up and after `SetTitleConsidered(true)` cleared it, and didn't crash the game, as the launch bar opens the panel any turn. Confirmed on Windows on 2026-10-27.

## Method

1. To read a choice that the `.modinfo` doesn't load yet, send the code as in [choices/production.md](production.md#method), step 4.
2. To appoint a governor without the panel, use the appoint action, as in [actions/governors.md](../actions/governors.md#method). It spends the title.

## Results

A single-player game with Gathering Storm, on turn 48, in `SentientSystemsCore_UI`:

- **The choices on the same turn.** `appoint` with Victor, Amani, Moksha, and Liang, each with loyalty 8 and 3 or 5 turns to establish.

  `promote` with 2 promotions each for Pingala, Magnus, and Reyna. `assign` with 8 cities each, 3,709 bytes. The same after the blocker was cleared, through the bridge's readers.
- **The choices after appointing Amani.** No `appoint`, as all 9 titles were spent. Amani's `assign` with the 9 cities and 8 city-state cities, 744 bytes.
- **The Governors panel after appointing Amani.** **Governor titles available: 0** and **Spent: 9**. Amani on **Needs Assignment** with a green **Assign** button, and **Appoint** turned off for Victor, Moksha, and Liang, as the choice has it. The assignment chooser's list wasn't shown.
- **The assignment chooser for Amani, who had no city.** Rome, Antium, Lugdunum, Setia, Ravenna, Ostia, Arpinum, Arretium, and Stockholm, then the city-states Kumasi, Zanzibar, Bologna, Nalanda, Valletta, Hunza, Jerusalem, and Hong Kong, in the choice's order, none turned off.

  The card read **The Diplomat**, 5 turns and loyalty 8, and **Replaces: No Governor Assigned** once a city was picked, and **Assign** turned on.

Date checked: game files on 2026-10-27. Running game on Windows on 2026-10-27.
