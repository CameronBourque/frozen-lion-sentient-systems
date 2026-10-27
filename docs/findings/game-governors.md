# Game governors

Status: open. The `governors` section of `SentientSystems_GetState`, the player's governor titles and appointed governors, is confirmed in a running game with Gathering Storm, with the file sent through the tuner, and matches the Governors panel. The governor choice, the promotion tree, and Secret Societies come later in this task.

The calls the governors in the state use, as the Governors panel shows them. See [in-game-lua.md](../design/core/in-game-lua.md).

## Questions

1. How do Secret Societies' governors, which `GovernorsCannotAssign` marks, and their hidden promotions read in the state?

## What we know now

### Governors panel

Rise and Fall adds `DLC/Expansion1/UI/Additions/GovernorPanel.lua`, with `GovernorSupport.lua`, `GovernorDetailsPanel.lua`, and `GovernorAssignmentChooser.lua`, and Gathering Storm has its own copies in `DLC/Expansion2/UI/Additions`. A player has `GetGovernors()` only with Rise and Fall. All four `ENDTURN_BLOCKING_GOVERNOR_` blockers open the panel. Confirmed in files.

- **Titles.** `Refresh`, lines 39 to 122, shows `GetGovernorPoints()` less `GetGovernorPointsSpent()` as the titles available, and the titles spent. On turn 48 they were 1 and 8. Closing the panel calls `SetTitleConsidered(true)`, which cleared `ENDTURN_BLOCKING_GOVERNOR_OPPORTUNITY` with the title still unspent. Confirmed in files and on Windows on 2026-10-27.
- **Appointed governors.** `GetGovernorList()` returns whether there are any, and the list, in the panel's order. Each has `GetType()`, an index in `GameInfo.Governors`, whose row has `Name`, `Title`, and `Hash`. `GetGovernorStatus` in `GovernorSupport.lua`, lines 72 to 95, reads `GetNeutralizedTurns()`, `GetAssignedCity()`, `IsEstablished()`, and `GetTurnsToEstablish()` less `GetTurnsOnSite()`, the turns until a governor settles in. Pingala was established in Rome, Magnus in Ravenna, and Reyna in Ostia. Confirmed in files and on Windows on 2026-10-27.
- **Promotions.** `AddGovernorAppointed`, lines 359 to 434, lists each row of `GameInfo.GovernorPromotionSets()` for the governor's type, and marks those for which `HasPromotion(promotionHash)` is `true`. A set can hold another governor's promotion, such as Pingala's `GOVERNOR_PROMOTION_MERCHANT_CURATOR`. Pingala had 4, Magnus 3, and Reyna 1. Confirmed in files and on Windows on 2026-10-27.
- **Loyalty pressure.** The panel shows the governor row's `IdentityPressure`, 8 for each, and `GetTurnsToEstablish(hash)` on the player's governors, 3 for Victor and 5 for the rest. The assignment chooser shows an appointed governor's own `GetIdentityPressure()`, which promotions can raise, so the state uses it. Each of the three was 8. Confirmed in files and on Windows on 2026-10-27.

## Method

1. To read a state section that the `.modinfo` doesn't load yet, send the code as in [game-choices.md](game-choices.md#method), step 6, and send `SentientSystemsCore_State.lua` again so it calls it.
2. Opening the Governors panel and closing it clears the governor blocker, so reload the save to see it again.

## Results

A single-player game with Gathering Storm, on turn 48, in `SentientSystemsCore_UI`:

| Check | Result |
| --- | --- |
| The state with three governors appointed | 1 title and 8 spent. Pingala in Rome, Magnus in Ravenna, and Reyna in Ostia, each established, with loyalty 8 and 5 turns to establish, and 4, 3, and 1 promotions. The panel showed **Governor titles available: 1**, **Spent: 8**, the same governors, cities, and earned promotions, and Victor, Amani, Moksha, and Liang as candidates |
| The state through the bridge's readers | Parsed, with the same values |

Date checked: game files on 2026-10-27. Running game on Windows on 2026-10-27.
