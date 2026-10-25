# Step 6: State: choices, blockers, and scoreboard

Add the second half of the state: the legal options for each discrete choice, what blocks the end of the turn, and the scoreboard a human can see. Part of [phase 1](README.md).

## Tasks

1. **Blockers.** Add the current end-turn blocker from `NotificationManager.GetFirstEndTurnBlocking`, and each unit that needs orders. List every `EndTurnBlockingTypes` value in the finding, with the screen that resolves each one. See [ending the turn](../../findings/game-api.md#ending-the-turn). Commit: `feat(core): add end-turn blockers to the state`.
2. **Production.** For each city, add the units, buildings, districts, and projects it can build, with cost, turns to complete, and the reason a blocked item can't be built. Read the checks from `ProductionPanel.lua`. Commit: `feat(core): add production options to the state`.
3. **Techs and civics.** Add the techs and civics that can be researched now, with turns to complete, boost status or boost requirement, and prerequisites. Read the checks from `ResearchChooser.lua` and `CivicsChooser.lua`. Commit: `feat(core): add tech and civic options to the state`.
4. **Policies.** Add the current government, its slots, the slotted policies, and the unlocked policies for each slot type. Read the checks from `GovernmentScreen.lua`. Commit: `feat(core): add policy options to the state`.
5. **Other blocker options.** For each other blocker in the list from task 1, such as a pantheon, an era dedication, or a promotion, add its legal options. Commit: `feat(core): add options for the other end-turn blockers`.
6. **Scoreboard.** Add each met player's score, and the victory progress that `WorldRankings.lua` shows. Leave out players not met yet. Commit: `feat(core): add the scoreboard to the state`.
7. **Bridge.** Add each section's schema in its own file in `src/state/`, as the core mod's Lua has one file for each section in `Scripts/State/`. Make `npm run state` print each section's size. Commit: `feat(core): read choices and the scoreboard in the bridge`.

## Done when

In a running game, each option list matches the game's own screen, a blocked item has a reason, and the blocker matches the **Next Turn** button's prompt.

## Record

- Each call and each blocker, in `findings/game-state.md`.
- The section sizes for one early turn, in [testing.md](../../design/testing.md#state-size).
