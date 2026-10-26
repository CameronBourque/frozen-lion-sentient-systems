# Step 6: State: choices, blockers, and scoreboard

Add what blocks the end of the turn and the scoreboard to the state, and add the choices and the tech and civic trees as calls of their own. Part of [phase 1](README.md).

## Tasks

Each task is one commit. A task that adds a key adds its Lua, its Lua tests, its schema in the bridge, and the schema's tests. Check each key in a running game against the screen the task names, and record what you find before you commit. [in-game-lua.md](../../design/core/in-game-lua.md) has the format of the state, the choices, and the trees.

### Blockers

1. **List the blockers.** In `findings/game-state.md`, list every `EndTurnBlockingTypes` value. For each one, name the screen that resolves it, and whether it needs an expansion. Read them from `DoEndTurn` in `ActionPanel.lua`, and from `NotificationPanel.lua`. See [ending the turn](../../findings/game-api.md#ending-the-turn). Commit: `docs(core): list the end-turn blockers`.
2. **Blockers in the state.** Add a `blockers` section to the state. It holds every blocker once, from `NotificationManager.GetAllEndTurnBlocking`, each with the choice in `choices` that resolves it, and the IDs of the units that need orders. Check it against the **Next Turn** button's prompt. Commit: `feat(core): add end-turn blockers to the state`.

### Choices

3. **Choices call.** Add `SentientSystems_GetChoices(playerID)` in `Scripts/Choices/SentientSystemsCore_Choices.lua`, which returns an empty table for now. Each choice gets its own file in `Scripts/Choices/`, as each state section has in `Scripts/State/`. In the bridge, move the piece reading out of `src/state/state.ts` so that `readState` and a new `readChoices` in `src/choices/choices.ts` share it. Make `npm run state` print the choices after the state. Commit: `feat(core): add the choices call`.
4. **Units.** Add `choices.production`, with one entry for each city. Each entry lists the units the production panel shows, with cost and turns. A unit the panel greys out has the panel's reason. Read the checks from `ProductionPanel.lua`. Commit: `feat(core): add unit production options`.
5. **Buildings.** Add the buildings to each city's entry, wonders left out, in the same form. Commit: `feat(core): add building production options`.
6. **Districts and wonders.** Add the districts and wonders, each with the tiles where it can go. Read the placement check from `ProductionPanel.lua`. Commit: `feat(core): add district and wonder production options`.
7. **Projects.** Add the projects. Commit: `feat(core): add project production options`.
8. **Gold purchases.** Add `choices.purchases`, with one entry for each city. Each entry lists the units and buildings the city can buy with gold, with the gold cost, and the reason for each one the panel greys out. Read the checks from the purchase tab in `ProductionPanel.lua`. Commit: `feat(core): add gold purchase options`.
9. **Faith purchases.** Add what each city can buy with faith, in the same form. Commit: `feat(core): add faith purchase options`.
10. **Tile purchases.** Add the tiles each city can buy with gold, with the cost of each. Read the check from `Base/Assets/UI/WorldView/PlotInfo.lua`. Commit: `feat(core): add tile purchase options`.

### Research

11. **Techs.** Add `choices.techs`, the techs that can be researched now. Each has turns, the boost status or what the boost needs, and its direct prerequisites. Read the checks from `ResearchChooser.lua`. Commit: `feat(core): add tech options`.
12. **Civics.** Add `choices.civics` in the same form, from `CivicsChooser.lua`. Commit: `feat(core): add civic options`.
13. **Tech tree.** Add `SentientSystems_GetTechTree(playerID)` and its reader in the bridge. It lists every node the tech tree screen shows, with type, era, cost, prerequisites, status, and boost. Build it from the running game, not from static data. For the Tech and Civic Shuffle mode, in `DLC/TreeRandomizer`, a node the screen shows as a `?` box is a placeholder with only its era. Read the screen from `TechTree.lua` and its replacements in `DLC/Expansion1` and `DLC/Expansion2`. Commit: `feat(core): add the tech tree`.
14. **Civic tree.** Add `SentientSystems_GetCivicTree(playerID)` in the same form, from `CivicsTree.lua`. Commit: `feat(core): add the civic tree`.

### Policies

15. **Government.** Add `choices.government`, with the current government, its slots, and the policy in each slot. Read the checks from `GovernmentScreen.lua` and its replacements in `DLC/Expansion1` and `DLC/Expansion2`. Commit: `feat(core): add the government to the choices`.
16. **Policy options.** Add the unlocked policies for each slot type, and whether the player can change policies now. Commit: `feat(core): add policy options`.

### Other blockers

Each task adds the options for the blockers in [end-turn blockers](../../findings/game-state.md#end-turn-blockers) that no earlier task covers, read from the screen that the finding names. Leave out each choice whose feature isn't in the ruleset.

17. **Pantheon.** Add `choices.pantheon`, for `ENDTURN_BLOCKING_PANTHEON`. Commit: `feat(core): add pantheon options`.
18. **Religion and beliefs.** Add `choices.religion`, for `ENDTURN_BLOCKING_RELIGION` and `ENDTURN_BLOCKING_BELIEF`. Commit: `feat(core): add religion and belief options`.
19. **Envoys.** Add `choices.envoys`, for `ENDTURN_BLOCKING_GIVE_INFLUENCE_TOKEN`. Commit: `feat(core): add envoy options`.
20. **Great people.** Add `choices.greatPeople`, for `ENDTURN_BLOCKING_CLAIM_GREAT_PERSON`. Commit: `feat(core): add great person options`.
21. **Captured cities.** Add `choices.capturedCities`, for `ENDTURN_BLOCKING_CONSIDER_RAZE_CITY` and `ENDTURN_BLOCKING_CONSIDER_DISLOYAL_CITY`. Commit: `feat(core): add captured city options`.
22. **Spies.** Add `choices.spies`, for `ENDTURN_BLOCKING_SPY_CHOOSE_ESCAPE_ROUTE` and `ENDTURN_BLOCKING_SPY_CHOOSE_DRAGNET_PRIORITY`. Commit: `feat(core): add spy options`.
23. **Artifacts.** Add `choices.artifacts`, for `ENDTURN_BLOCKING_ARTIFACT`. Commit: `feat(core): add artifact options`.
24. **Governors.** Add `choices.governors`, for the four `ENDTURN_BLOCKING_GOVERNOR_` blockers. Commit: `feat(core): add governor options`.
25. **Era dedications.** Add `choices.dedications`, for `ENDTURN_BLOCKING_COMMEMORATION_AVAILABLE`. Commit: `feat(core): add era dedication options`.
26. **Emergencies.** Add `choices.emergencies`, for `ENDTURN_BLOCKING_EMERGENCY_NEEDS_ATTENTION`. Commit: `feat(core): add emergency options`.
27. **World Congress.** Add `choices.worldCongress`, for `ENDTURN_BLOCKING_WORLD_CONGRESS_LOOK` and `ENDTURN_BLOCKING_WORLD_CONGRESS_SESSION`. Commit: `feat(core): add World Congress options`.

### Scoreboard

28. **Scores.** Add a `scoreboard` section to the state with each player's score, as the **Score** tab of World Rankings shows it. Commit: `feat(core): add scores to the state`.
29. **Victory progress.** Add the progress for each victory, as World Rankings shows it. List every player in the screen's order. A met player has their ID and the values the tab and its tooltips show. An unmet player has only their place in the order, as the screen shows a `?` icon. Read the screen from `WorldRankings.lua` and `WorldRankings_Expansion2.lua`. Commit: `feat(core): add victory progress to the state`.

### Sizes

30. **Section sizes.** Make `npm run state` print the size of each section of the state, of the choices, and of each tree. Commit: `feat(core): print the state's section sizes`.

## Done when

In a running game, each option list matches the game's own screen, a greyed-out item has the screen's reason, the blocker matches the **Next Turn** button's prompt, and the scoreboard matches World Rankings.

## Record

- Each call for the state and each blocker, in [game-state.md](../../findings/game-state.md), and each call for the choices and the trees, in [game-choices.md](../../findings/game-choices.md).
- The choices, the trees, the blockers, and the scoreboard, in [in-game-lua.md](../../design/core/in-game-lua.md).
- The section sizes for one early turn, in [testing.md](../../design/testing.md#state-size).
