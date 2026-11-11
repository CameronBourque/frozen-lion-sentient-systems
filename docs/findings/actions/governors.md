# Governor actions

Status: open. Appointing, promoting, and assigning a governor to the player's own city and to a city-state's city are confirmed in a running game with Gathering Storm, with the files sent through the tuner. A city the chooser turns off wasn't seen.

The game calls that the appoint, promote, and assign actions wrap, with the Lua state they run in and what the game checks. The governors, promotions, and cities the player can pick are in [choices/governors.md](../choices/governors.md).

The core mod's result format is in [design/core/mod/actions/README.md](../../design/core/mod/actions/README.md). The other actions are in the [actions index](README.md).

## Questions

1. What reasons does `CanAssignGovernor` give for a city-state's city or a capital it turns off, and does the action's reason read well with them? None of the 8 city-states met was turned off.

## What we know now

### Requests

Each request is `UI.RequestPlayerOperation(Game.GetLocalPlayer(), operation, parameters)`. The governor in `PARAM_GOVERNOR_TYPE` and the promotion in `PARAM_GOVERNOR_PROMOTION_TYPE` are indexes in `GameInfo.Governors` and `GameInfo.GovernorPromotions`, not hashes.

The files are in `DLC/Expansion2/UI/Additions/`. Confirmed in files.

- **Appoint.** `OnAppointGovernor` in `GovernorPanel.lua` and `GovernorDetailsPanel.lua` sends `PlayerOperations.APPOINT_GOVERNOR` with `PARAM_GOVERNOR_TYPE`.
- **Promote.** `OnPromoteGovernor` in both files sends `PlayerOperations.PROMOTE_GOVERNOR` with `PARAM_GOVERNOR_TYPE` and `PARAM_GOVERNOR_PROMOTION_TYPE`.
- **Assign.** `ConfirmedAssignment` in `GovernorAssignmentChooser.lua` sends `PlayerOperations.ASSIGN_GOVERNOR` with `PARAM_GOVERNOR_TYPE`, `PARAM_PLAYER_ONE`, the city's owner, and `PARAM_CITY_DEST`, its ID.

  `OnAssignToCity` in `GovernorPanel.lua` sends the same without the owner. The assignment chooser's version also reaches the cities of other players, so the action sends that one.

### What the game takes

`UI.CanStartPlayerOperation(playerID, operation, parameters, false)` returned `true` with no reasons for each request the panel wouldn't send:

- Appointing a governor the player has, and Ibrahim, whom the panel never offers.
- Promoting a governor to a promotion they hold, and to another governor's promotion.
- Assigning a governor to the city they are in.

So each action checks the panel's rules itself, with the calls in [choices/governors.md](../choices/governors.md). Confirmed on Windows on 2026-11-10.

### What the requests do

1.5 seconds after each request, in `SentientSystemsCore_UI`:

- After the appointment, the governor was in `GetGovernorList()` with no city and its base promotion.
- After the promotion, `HasPromotion` was `true` for it. The appointment and the promotion took `GetGovernorPointsSpent()` from 9 to 11.
- After the assignment, `GetAssignedCity()` was the city and `IsEstablished()` was `false`. A governor moved from an established city started again in the new one.
- After Amani's assignment to Valletta, the assignment chooser's list no longer held Valletta.

Confirmed on Windows on 2026-11-10.

## Method

1. Send `Scripts/SentientSystemsCore_Governors.lua`, then `Scripts/Actions/SentientSystemsCore_ActionsGovernors.lua`, to `SentientSystemsCore_UI`, as in [choices/production.md](../choices/production.md#method), step 4.
2. Read the governors choice with `SentientSystems_GetChoices(0)`, and pick a governor, a promotion, and a city from it.
3. To see what the game takes, call `UI.CanStartPlayerOperation` with the panel's parameters for a request the choice doesn't list.
4. To get more titles, send `Players[0]:GetGovernors():ChangeGovernorPoints(1)` in `GameCore_Tuner`.
5. Call `appointGovernor`, `promoteGovernor`, and `assignGovernor` from the bridge. Wait 1.5 seconds, then read `GetGovernorList()`, each governor's `GetAssignedCity()` and `HasPromotion`, and `GetGovernorPointsSpent()` on `Players[0]:GetGovernors()`.

## Results

A single-player game with Gathering Storm, on Rome's save with 11 cities and 2 of 11 titles left. Pingala was established in Rome, Magnus in Ravenna, and Reyna in Ostia.

| Call | Result |
| --- | --- |
| `appointGovernor(GOVERNOR_THE_EDUCATOR)` | `You have appointed GOVERNOR_THE_EDUCATOR already.` |
| `appointGovernor(GOVERNOR_IBRAHIM)` | `You can't appoint GOVERNOR_IBRAHIM. ...` |
| `promoteGovernor(GOVERNOR_THE_DEFENDER, ...)`, before Victor was appointed | `You haven't appointed GOVERNOR_THE_DEFENDER. Appoint them first.` |
| `promoteGovernor(GOVERNOR_THE_EDUCATOR, GOVERNOR_PROMOTION_MERCHANT_HARBORMASTER)` | `... isn't a promotion of GOVERNOR_THE_EDUCATOR. ...` |
| `promoteGovernor(GOVERNOR_THE_EDUCATOR, GOVERNOR_PROMOTION_EDUCATOR_LIBRARIAN)` | `GOVERNOR_THE_EDUCATOR has GOVERNOR_PROMOTION_EDUCATOR_LIBRARIAN already.` |
| `promoteGovernor(GOVERNOR_THE_MERCHANT, GOVERNOR_PROMOTION_MERCHANT_CONTRACTOR)` | `GOVERNOR_THE_MERCHANT can't earn GOVERNOR_PROMOTION_MERCHANT_CONTRACTOR yet. ...` |
| `assignGovernor(GOVERNOR_THE_MERCHANT, 0, 393221)`, Ostia | `GOVERNOR_THE_MERCHANT is in that city already.` |
| `assignGovernor(GOVERNOR_THE_MERCHANT, 0, 1)` | `City 1 of player 0 isn't a place GOVERNOR_THE_MERCHANT can go. ...` |
| `appointGovernor(GOVERNOR_THE_DEFENDER)` | `{"ok":true}`. Victor was appointed with Redoubt and no city |
| `promoteGovernor(GOVERNOR_THE_MERCHANT, GOVERNOR_PROMOTION_MERCHANT_HARBORMASTER)` | `{"ok":true}`. Reyna held Harbormaster, and all 11 titles were spent |
| `appointGovernor(GOVERNOR_THE_AMBASSADOR)`, after that | `You have no governor title to spend. ...` |
| `promoteGovernor(GOVERNOR_THE_MERCHANT, GOVERNOR_PROMOTION_MERCHANT_TAX_COLLECTOR)`, after that | `You have no governor title to spend on GOVERNOR_THE_MERCHANT. ...` |
| `assignGovernor(GOVERNOR_THE_DEFENDER, 0, 131073)` | `{"ok":true}`. Victor was in Antium, not yet established |
| `assignGovernor(GOVERNOR_THE_MERCHANT, 0, 458758)` | `{"ok":true}`. Reyna moved from Ostia to Arpinum, not yet established |
| `SentientSystems_AppointGovernor(0, "GOVERNOR_THE_AMBASSADOR")`, after a title from the tuner | `{"ok":true}`. Amani had no city, and her list held the 8 city-states met, none turned off |
| `SentientSystems_AssignGovernor(0, "GOVERNOR_THE_AMBASSADOR", 27, 65536)`, Valletta | `{"ok":true}`. Valletta left her list |

Date checked: game files on 2026-11-10. Running game on Windows on 2026-11-10.
