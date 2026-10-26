# Step 6: State: choices, blockers, and scoreboard

Add what blocks the end of the turn, the player's overview, and the scoreboard to the state, and add the choices, the placement tiles, and the tech and civic trees as calls of their own. Part of [phase 1](README.md).

## Tasks

Each task is one commit. A task that adds a key adds its Lua, its Lua tests, its schema in the bridge, and the schema's tests. Check each key in a running game against the screen the task names, and record what you find before you commit. [in-game-lua.md](../../design/core/in-game-lua.md) has the format of the state, the choices, the placement tiles, and the trees.

### Blockers

1. **List the blockers.** In `findings/game-state.md`, list every `EndTurnBlockingTypes` value. For each one, name the screen that resolves it, and whether it needs an expansion. Read them from `DoEndTurn` in `ActionPanel.lua`, and from `NotificationPanel.lua`. See [ending the turn](../../findings/game-api.md#ending-the-turn). Commit: `docs(core): list the end-turn blockers`.
2. **Blockers in the state.** Add a `blockers` section to the state. It holds every blocker once, from `NotificationManager.GetAllEndTurnBlocking`, each with the choice in `choices` that resolves it, and the IDs of the units that need orders. Check it against the **Next Turn** button's prompt. Commit: `feat(core): add end-turn blockers to the state`.

### Choices

3. **Choices call.** Add `SentientSystems_GetChoices(playerID)` in `Scripts/Choices/SentientSystemsCore_Choices.lua`, which returns an empty table for now. Each choice gets its own file in `Scripts/Choices/`, as each state section has in `Scripts/State/`. In the bridge, move the piece reading out of `src/state/state.ts` so that `readState` and a new `readChoices` in `src/choices/choices.ts` share it. Make `npm run state` print the choices after the state. Commit: `feat(core): add the choices call`.
4. **Units.** Add `choices.production`, with one entry for each city. Each entry lists the units the production panel shows, with cost and turns. A unit the panel greys out has the panel's reason. Read the checks from `ProductionPanel.lua`. Commit: `feat(core): add unit production options`.
5. **Buildings.** Add the buildings to each city's entry, wonders left out, in the same form. Commit: `feat(core): add building production options`.
6. **Districts and wonders.** Add the districts and wonders, each with the tiles where it can go. Read the placement check from `ProductionPanel.lua`. Commit: `feat(core): add district and wonder production options`.
7. **Placement file.** Move the tile code out of `SentientSystemsCore_ChoicesProduction.lua` into `Scripts/Placement/SentientSystemsCore_Placement.lua`: the tiles the city owns, the tiles it could buy, and the adjacency bonuses. The production file keeps the panel's checks, which count the tiles. The choices don't change, so the bridge doesn't either. Commit: `refactor(core): move the placement tiles into their own file`.
8. **Placement call.** Add `SentientSystems_GetPlacement(playerID, cityID, type)` to the placement file. It returns the `tiles` and `purchaseTiles` of one district or wonder, as the placement view shows them when the player picks it. Take `tiles` and `purchaseTiles` out of the districts and wonders in `choices.production`. In the bridge, add `readPlacement` in `src/placement/placement.ts`, through the stash reader, and move the tile schema there from `src/choices/production.ts`. Commit: `feat(core): add the placement call`.
9. **Projects.** Add the projects. Commit: `feat(core): add project production options`.
10. **Gold purchases.** Add `choices.purchases`, with one entry for each city. Each entry lists the units and buildings the city can buy with gold, with the gold cost, and the reason for each one the panel greys out. Read the checks from the purchase tab in `ProductionPanel.lua`. Commit: `feat(core): add gold purchase options`.
11. **Faith purchases.** Add what each city can buy with faith, in the same form. Commit: `feat(core): add faith purchase options`.
12. **Tile purchases.** Add the tiles each city can buy with gold, with the cost of each. Read the check from `Base/Assets/UI/WorldView/PlotInfo.lua`, and reuse the tiles to buy from the placement file. Commit: `feat(core): add tile purchase options`.

### Research

13. **Techs.** Add `choices.techs`, the techs that can be researched now. Each has turns, the boost status or what the boost needs, and its direct prerequisites. Read the checks from `ResearchChooser.lua`. Commit: `feat(core): add tech options`.
14. **Civics.** Add `choices.civics` in the same form, from `CivicsChooser.lua`. Commit: `feat(core): add civic options`.
15. **Tech tree.** Add `SentientSystems_GetTechTree(playerID)` and its reader in the bridge. It lists every node the tech tree screen shows, with type, era, cost, prerequisites, status, and boost. Build it from the running game, not from static data. For the Tech and Civic Shuffle mode, in `DLC/TreeRandomizer`, a node the screen shows as a `?` box is a placeholder with only its era. Read the screen from `TechTree.lua` and its replacements in `DLC/Expansion1` and `DLC/Expansion2`. Commit: `feat(core): add the tech tree`.
16. **Civic tree.** Add `SentientSystems_GetCivicTree(playerID)` in the same form, from `CivicsTree.lua`. Commit: `feat(core): add the civic tree`.

### Policies

17. **Government.** Add `choices.government`, with the current government, its slots, and the policy in each slot. Read the checks from `GovernmentScreen.lua` and its replacements in `DLC/Expansion1` and `DLC/Expansion2`. Commit: `feat(core): add the government to the choices`.
18. **Policy options.** Add the unlocked policies for each slot type, and whether the player can change policies now. Commit: `feat(core): add policy options`.

### Other blockers

Each task adds the options for the blockers in [end-turn blockers](../../findings/game-state.md#end-turn-blockers) that no earlier task covers, read from the screen that the finding names. Leave out each choice whose feature isn't in the ruleset.

19. **Pantheon.** Add `choices.pantheon`, for `ENDTURN_BLOCKING_PANTHEON`. Commit: `feat(core): add pantheon options`.
20. **Religion and beliefs.** Add `choices.religion`, for `ENDTURN_BLOCKING_RELIGION` and `ENDTURN_BLOCKING_BELIEF`. Add the player's pantheon, religion, and its followers to the state, as the Religion screen shows them. Commit: `feat(core): add religion and belief options`.
21. **Envoys.** Add `choices.envoys`, for `ENDTURN_BLOCKING_GIVE_INFLUENCE_TOKEN`. Add the envoy tokens, and each met city-state's envoys and suzerain, to the state, as the City-States screen shows them, from `CityStates.lua` and its replacements. Commit: `feat(core): add envoy options`.
22. **Great people.** Add `choices.greatPeople`, for `ENDTURN_BLOCKING_CLAIM_GREAT_PERSON`. Add each candidate's era and effect, each met player's recruit progress, the player's points per turn, and the gold and faith patronage costs to the state, as the Great People screen shows them, from `GreatPeoplePopup.lua` and its replacements. Commit: `feat(core): add great person options`.
23. **Captured cities.** Add `choices.capturedCities`, for `ENDTURN_BLOCKING_CONSIDER_RAZE_CITY` and `ENDTURN_BLOCKING_CONSIDER_DISLOYAL_CITY`. Commit: `feat(core): add captured city options`.
24. **Spies.** Add `choices.spies`, for `ENDTURN_BLOCKING_SPY_CHOOSE_ESCAPE_ROUTE` and `ENDTURN_BLOCKING_SPY_CHOOSE_DRAGNET_PRIORITY`. Commit: `feat(core): add spy options`.
25. **Artifacts.** Add `choices.artifacts`, for `ENDTURN_BLOCKING_ARTIFACT`. Commit: `feat(core): add artifact options`.
26. **Governors.** Add `choices.governors`, for the four `ENDTURN_BLOCKING_GOVERNOR_` blockers. Add the appointed governors, their cities, and their promotions to the state, as the Governors panel shows them. Commit: `feat(core): add governor options`.
27. **Era dedications.** Add `choices.dedications`, for `ENDTURN_BLOCKING_COMMEMORATION_AVAILABLE`. Commit: `feat(core): add era dedication options`.
28. **Emergencies.** Add `choices.emergencies`, for `ENDTURN_BLOCKING_EMERGENCY_NEEDS_ATTENTION`. Commit: `feat(core): add emergency options`.
29. **World Congress.** Add `choices.worldCongress`, for `ENDTURN_BLOCKING_WORLD_CONGRESS_LOOK` and `ENDTURN_BLOCKING_WORLD_CONGRESS_SESSION`. Commit: `feat(core): add World Congress options`.

### Player

Each task adds what a screen shows about the player as a whole, in a `player` section of the state, except where the task names another section.

30. **Top bar.** Add the gold and faith balances, and the science, culture, faith, gold, and tourism per turn, as the top bar shows them. Read them from `TopPanel.lua` and its replacements in `DLC/Expansion1` and `DLC/Expansion2`. Commit: `feat(core): add the top bar to the state`.
31. **Income and upkeep.** Add the income by source, the building and unit upkeep, the deal payments, and the net income per turn, as the **Yields** tab of Reports shows them. Read them from `ReportScreen.lua` and its replacements. Commit: `feat(core): add income and upkeep to the state`.
32. **Resources.** Add the strategic and luxury resources the player has, and with Gathering Storm the strategic stockpiles, as the **Resources** tab of Reports shows them. Commit: `feat(core): add resources to the state`.
33. **City status.** Add each city's growth rate status, war weariness, and governor to `cities`, as the **City Status** tab of Reports shows them. Commit: `feat(core): add city status to the state`.
34. **Era.** Add the era, era score, current age, the thresholds for the next age, turns until the next era, and the active effects, as the Era Progress panel shows them, from `EraProgressPanel.lua` in `DLC/Expansion1` and `DLC/Expansion2`. Leave it out without Rise and Fall. Commit: `feat(core): add era progress to the state`.
35. **Diplomacy.** Add a `diplomacy` section with war or peace with each met player, and each deal another player proposes, as the diplomacy screens show them. Read them from `DiplomacyActionView.lua`, `DiplomacyDealView.lua`, and their replacements. Commit: `feat(core): add diplomacy status to the state`.

### Scoreboard

36. **Scores.** Add a `scoreboard` section to the state with each player's score, as the **Score** tab of World Rankings shows it. Add each met player's military strength, and science, culture, gold, and faith per turn, as the leader panel at the top right shows them, from `DiplomacyRibbon.lua` and its replacements. Commit: `feat(core): add scores to the state`.
37. **Victory progress.** Add the progress for each victory, as World Rankings shows it. List every player in the screen's order. A met player has their ID and the values the tab and its tooltips show. An unmet player has only their place in the order, as the screen shows a `?` icon. Read the screen from `WorldRankings.lua` and `WorldRankings_Expansion2.lua`. Commit: `feat(core): add victory progress to the state`.

### Sizes

38. **Section sizes.** Make `npm run state` print the size of each section of the state, of the choices, and of each tree. Commit: `feat(core): print the state's section sizes`.

## Done when

In a running game, each option list matches the game's own screen, a greyed-out item has the screen's reason, the blocker matches the **Next Turn** button's prompt, each part of the player's overview matches the screen it comes from, and the scoreboard matches World Rankings and the leader panel.

## Record

- Each call for the state and each blocker, in [game-state.md](../../findings/game-state.md), and each call for the choices, the placement tiles, and the trees, in [game-choices.md](../../findings/game-choices.md).
- The choices, the placement tiles, the trees, the blockers, the player's overview, and the scoreboard, in [in-game-lua.md](../../design/core/in-game-lua.md), and `readPlacement` in [bridge.md](../../design/core/bridge.md).
- The section sizes for one early turn, in [testing.md](../../design/testing.md#state-size).
