# Game great people

Status: open. The `greatPeople` key of `SentientSystems_GetChoices`, the great people the player can recruit or pass, and the `greatPeople` section of `SentientSystems_GetState`, each great person on offer with their effects, patronage, and each player's progress, are confirmed in a running game with Gathering Storm, with the files sent through the tuner, and match the Great People screen.

The calls the great person choice and the great people section of the state use, as the Great People screen shows them. The other choices are in [game-choices.md](game-choices.md). See [in-game-lua.md](../design/core/in-game-lua.md).

## Questions

None open.

## What we know now

### Great People screen

`Base/Assets/UI/Popups/GreatPeoplePopup.lua` draws the Great People screen. Rise and Fall and Gathering Storm replace it with `GreatPeoplePopup_Expansion1.lua`, which shows a patronage tooltip as off when the player's `GetGreatPeoplePoints():IsNoPatronageWith(yieldIndex)` is `true`, and Gathering Storm adds `GreatPeoplePopup_Expansion2.lua`, whose `IsReadOnly` is `true` while the World Congress is in session. Confirmed in files.

- **Timeline.** `PopulateData`, lines 682 to 778, reads `Game.GetGreatPeople():GetTimeline()`. Each entry has `Individual`, an index in `GameInfo.GreatPersonIndividuals`, `Class`, `Era`, `Cost`, `PassiveNameText`, `PassiveEffectText`, `ActionNameText`, `ActionUsageText`, and `ActionEffectText`. An entry with no `Individual` shows as claimed. An individual's row has `ActionCharges`, which the screen shows when above 0. On turn 16 the timeline had 9 entries, one for each class but the Comandante General, such as Sun Tzu for 30 points in the Classical Era. Sun Tzu and Themistocles had `PassiveNameText` "Passive Effect", and the other 7 an empty one. Confirmed in files and on Windows on 2026-10-26.
- **Recruit and pass.** `AddRecruit`, lines 265 to 287, shows **Recruit** when `CanRecruitPerson(playerID, individual)` is `true` and **Pass** when `CanRejectPerson` is, each with its capability, `CAPABILITY_GREAT_PEOPLE_CAN_RECRUIT` and `CAPABILITY_GREAT_PEOPLE_CAN_REJECT`. `GetRejectCost` is the points passing costs, 6 for a 30-point great person. Recruiting sends `PlayerOperations.RECRUIT_GREAT_PERSON`, and passing `REJECT_GREAT_PERSON`, each with the individual in `PARAM_GREAT_PERSON_INDIVIDUAL_TYPE`. With 42 scientist points from the tuner, the player could recruit Aryabhata or pass, and `ENDTURN_BLOCKING_CLAIM_GREAT_PERSON` was among the blockers. Confirmed in files and on Windows on 2026-10-26.
- **Patronage.** Lines 241 to 262 show a gold and a faith button, each with `CAPABILITY_GREAT_PEOPLE_RECRUIT_WITH_GOLD` or `_FAITH`, while the player can neither recruit nor pass the great person and `GetPatronizeCost(playerID, individual, YieldTypes.GOLD)` is below 1,000,000. `CanPatronizePerson` turns the button on, and `IsReadOnly` turns it off. Patronizing sends `PlayerOperations.PATRONIZE_GREAT_PERSON` with the yield in `PARAM_YIELD_TYPE`. Sun Tzu cost 650 gold or 450 faith, and the button for gold turned on once the player had 722 gold. Confirmed in files and on Windows on 2026-10-26.
- **Can't earn.** `GetEarnConditionsText` gives the reason the player can't earn a great person, which the screen shows as **Cannot Recruit**, and an empty text otherwise. For Themistocles, with no coastal city, it was "You must have a coastal city center or a Harbor district in order to spawn a Great Admiral.", and each cost was 2147483647. Confirmed in files and on Windows on 2026-10-26.
- **Progress.** Lines 780 to 814 list each player from `Game.GetPlayers{Major = true, Alive = true}` for each class, with `GetGreatPeoplePoints():GetPointsTotal(classIndex)` and `GetPointsPerTurn(classIndex)`, and name a player the player hasn't met as an unmet player. `AddRecruit`, lines 296 to 321, sorts them by points, most first, then by player ID, for the expanded recruit list, and `FillRecruitInstance` rounds both to one decimal. The card itself shows the player first, then the others in that order, so the state's order is the expanded list's. A player's own `HasMet` for itself was `false`, so the screen checks the player first. Confirmed in files and on Windows on 2026-10-26.
- **Left out.** The state leaves out each great person's biography and the **Previously Recruited** tab. Confirmed in files.

## Method

1. To read a choice or a state section that the `.modinfo` doesn't load yet, send the code as in [game-choices.md](game-choices.md#method), step 6, and send `SentientSystemsCore_State.lua` and `SentientSystemsCore_Choices.lua` again so they call it. Send a new function in `SentientSystemsCore_Common.lua` by itself, as stripping the include lines also strips `SentientSystems_Include`.
2. To give a player great person points, send `Players[0]:GetGreatPeoplePoints():ChangePointsTotal(classIndex, points)` in `GameCore_Tuner`. It kept 12 of 12.5 points, so the points look like whole numbers.
3. To afford patronage, send `Players[0]:GetTreasury():ChangeGoldBalance(600)` in `GameCore_Tuner`.

## Results

A single-player game with Gathering Storm, on turn 16 of Rome's save with a religion, in `SentientSystemsCore_UI`:

| Check | Result |
| --- | --- |
| The great people before any change | 9, from Sun Tzu to Dimitrie Cantemir, with no choice. Themistocles with `cantEarn` and no patronage, and the rest with patronage the player couldn't afford. Rome had 2 prophet points at 2 per turn and 2 scientist points at 1 per turn, and player 1 none. 5,180 bytes |
| After 40 scientist points for Rome, 12.5 merchant points for player 1, and 600 gold | The choice `[{"passCost":6,"recruit":true,"type":"GREAT_PERSON_INDIVIDUAL_ARYABHATA"}]`, and `ENDTURN_BLOCKING_CLAIM_GREAT_PERSON` with `"choice":"greatPeople"`. Aryabhata with no patronage. Zhang Qian with gold patronage on at 650, and player 1 first with 12 points |
| The state and choices through the bridge's readers | Both parsed, with the same values |
| The Great People screen after the same changes | The same 9 great people in the same order, with the same eras, effects, and patronage costs, such as 650 gold and 450 faith for Sun Tzu. Themistocles with **Cannot Recruit** and no patronage. Aryabhata with **Recruit** and **Pass**, no patronage, and Rome at 42/30. Each card with Rome first, then Egypt, such as Zhang Qian's with Rome at 0/30 and Egypt at 12/30 |

Date checked: game files on 2026-10-26. Running game on Windows on 2026-10-26.
