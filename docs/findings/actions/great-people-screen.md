# Great People screen actions

Status: confirmed. Recruiting, passing, and patronizing a great person are confirmed in a running game with Gathering Storm.

The game calls that the recruit, pass, and patronize actions wrap, with the Lua state they run in and what the game checks. The great people on offer are in [choices/great-people.md](../choices/great-people.md). Activating a great person unit is in [great-people.md](great-people.md).

The core mod's result format is in [design/core/mod/actions/README.md](../../design/core/mod/actions/README.md). The other actions are in the [actions index](README.md).

## Questions

None open.

## What we know now

### Requests

`Base/Assets/UI/Popups/GreatPeoplePopup.lua` sends each request with `UI.RequestPlayerOperation(Game.GetLocalPlayer(), operation, parameters)`. The parameters hold the individual's index in `GameInfo.GreatPersonIndividuals`, not its hash, in `PARAM_GREAT_PERSON_INDIVIDUAL_TYPE`. Confirmed in files.

- `OnRecruitButtonClick` sends `PlayerOperations.RECRUIT_GREAT_PERSON`.
- `OnRejectButtonClick` sends `PlayerOperations.REJECT_GREAT_PERSON`.
- `OnGoldButtonClick` and `OnFaithButtonClick` send `PlayerOperations.PATRONIZE_GREAT_PERSON`, with `YieldTypes.GOLD` or `YieldTypes.FAITH` in `PARAM_YIELD_TYPE`.
- None of the handlers checks before its request, because the screen shows each button only when the game allows it.
- `IsReadOnly` in `GreatPeoplePopup_Expansion2.lua`, true while the World Congress is in session, turns off only the patronage buttons. Confirmed in files.

### The game's checks

- `UI.CanStartPlayerOperation(playerID, operation, parameters, false)` returned `true` for a recruit and a pass of a great person with 2 of 30 points, and for patronage with gold the player couldn't afford.

  So the actions check `CanRecruitPerson`, `CanRejectPerson`, and `CanPatronizePerson` themselves. Confirmed on Windows on 2026-11-09.
- After a pass, `CanRecruitPerson` and `CanRejectPerson` are `false` for the same great person, though the player has the points. `GetEarnConditionsText` then gives "You have already chosen to Pass on this Great Person.", and `GetRejectCost` gives 2147483647. Confirmed on Windows on 2026-11-09.

### Results of a request

The requests run in `SentientSystemsCore_UI`. Each one below was read 1.5 seconds after it. Confirmed on Windows on 2026-11-09.

- **Recruit.** The great person's unit appears, the class's points drop by the cost, and the next great person of the class goes on offer.
- **Pass.** The class's points drop by `GetRejectCost`, and the same great person stays on offer.
- **Patronize.** The yield drops by the cost, and the unit appears, as for a recruit.
- **Blocker.** `ENDTURN_BLOCKING_CLAIM_GREAT_PERSON` clears once no great person is left that the player can recruit.

## Method

1. Send `Scripts/SentientSystemsCore_GreatPeople.lua`, then `Scripts/Actions/SentientSystemsCore_ActionsGreatPeople.lua`, to `SentientSystemsCore_UI`, as in [choices/production.md](../choices/production.md#method), step 4.
2. To give a player the points to recruit, follow [choices/great-people.md](../choices/great-people.md#method), step 2.
3. Call `recruitGreatPerson`, `passGreatPerson`, and `patronizeGreatPerson` from the bridge. Wait 1.5 seconds, then read the player's units, faith, points, and `Game.GetGreatPeople():GetTimeline()`.
4. To see what the game takes, call `UI.CanStartPlayerOperation` with the screen's parameters for a great person the player can't claim.

## Results

A single-player game with Gathering Storm, on Rome's save on turn 15 with a pantheon, in `SentientSystemsCore_UI`, for player 0, with 107 gold and 992 faith:

| Call | Result |
| --- | --- |
| `recruitGreatPerson(SIDDHARTHA_GAUTAMA)`, with 2 of 30 prophet points | `You can't recruit ... yet. It costs 30 points, and you have 2.` |
| `passGreatPerson(SIDDHARTHA_GAUTAMA)` | The same reason, with `pass` |
| `patronizeGreatPerson(SIDDHARTHA_GAUTAMA, "gold")`, at 620 gold | `You can't afford ... with gold. It costs 620.` |
| `patronizeGreatPerson(THEMISTOCLES, "faith")`, with no coastal city | `You can't claim ...`, with the screen's text on the coastal city |
| `patronizeGreatPerson(SIDDHARTHA_GAUTAMA, "faith")`, at 430 faith | `{"ok":true}`. A Great Prophet appeared at (17, 14), the faith became 562, and Confucius went on offer |
| `patronizeGreatPerson(ARYABHATA, "gold")`, with 41 of 30 scientist points | `You have the points for ..., so recruit or pass them instead.` |
| `passGreatPerson(ARYABHATA)` | `{"ok":true}`. The points became 35, and Aryabhata stayed on offer |
| `recruitGreatPerson(ZHANG_QIAN)`, with 40 of 30 merchant points | `{"ok":true}`. A Great Merchant appeared, the points became 10, and Colaeus went on offer |
| `recruitGreatPerson(ARYABHATA)`, after the pass | `You can't claim ...`, with the game's text on the pass |

The type `GREAT_PERSON_INDIVIDUAL_MOSES` isn't in this ruleset, and the action returned that it isn't a great person.

Date checked: 2026-11-09.
