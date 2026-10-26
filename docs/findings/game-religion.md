# Game religion

Status: open. The `pantheon` key of `SentientSystems_GetChoices`, the pantheon beliefs the player can found a pantheon with, and the `religion` section of `SentientSystems_GetState`, the player's pantheon, progress toward a religion, and founded religion, are confirmed in a running game with Gathering Storm. The faith for the next pantheon is confirmed through its call, not through the state.

The calls the religion choices and the religion section of the state use, as the game's religion screens show them. The other choices are in [game-choices.md](game-choices.md). See [in-game-lua.md](../design/core/in-game-lua.md).

## Questions

None open.

## What we know now

### Pantheon

`Base/Assets/UI/Choosers/PantheonChooser.lua` draws the pantheon chooser. The expansions load the same file and don't replace it. Confirmed in files.

- **Opening.** `LaunchBar.lua`, lines 136 to 140, opens the chooser when `player:GetReligion():GetPantheon()` is below 0 and `CanCreatePantheon()` is `true`. `GetPantheon()` returns the index of the pantheon's belief in `GameInfo.Beliefs`, or -1 for none. With 100 faith added on turn 14, `CanCreatePantheon()` stayed `false` until turn 15. Confirmed in files and on Windows on 2026-10-26.
- **Beliefs.** `Realize`, lines 23 to 44, lists each row of `GameInfo.Beliefs()` that `CanSelectBelief`, lines 63 to 72, allows: its `BeliefClassType` is `BELIEF_CLASS_PANTHEON`, and `Game.GetReligion():IsInSomePantheon(index)` and `IsInSomeReligion(index)` are both `false`. Each card shows the belief's `Name` and `Description`. On turn 19 of a later save, `IsInSomePantheon` was `true` for Desert Folklore, Egypt's pantheon, and for Religious Settlements, the player's. Confirmed in files and on Windows on 2026-10-26.
- **Founding.** `ConfirmPantheon`, lines 120 to 131, sends `PlayerOperations.FOUND_PANTHEON` with the belief's hash in `PARAM_BELIEF_TYPE`. Confirmed in files.

### Religion screen

`Base/Assets/UI/ReligionScreen.lua` draws the religion screen. The expansions load the same file, and only scenarios replace it. Confirmed in files.

- **Stage.** `ViewMyReligion`, lines 308 to 336, reads `player:GetReligion()`. With `GetPantheon()` below 0, it shows `GetMinimumFaithNextPantheon()` on `Game.GetReligion()`, 12 on turn 15. With a pantheon and `GetNumBeliefsEarned()` at 0, it shows whether `HasReligiousFoundingUnit()` is `true`, a Great Prophet. Then it offers a religion while `GetReligionTypeCreated()` is below 0, beliefs while more are earned than the religion has, and the religion otherwise. Confirmed in files and on Windows on 2026-10-26.
- **Founded religion.** `ViewReligion`, lines 964 to 1170, finds the religion in `Game.GetReligion():GetReligions()`, whose entries have `Religion`, an index in `GameInfo.Religions`, `Founder`, and `Beliefs`, a list of belief indexes. `Game.GetReligion():GetName(index)` gives its name as a text key. `GetHolyCityID()` returns a table with `type`, `player`, and `id`, which `CityManager.GetCity` takes. The screen shows one locked belief slot for each belief an Apostle can still add, which the state leaves out. Confirmed in files and on Windows on 2026-10-26.
- **Followers.** The screen counts the cities of every living player where `city:GetReligion():GetMajorityReligion()` is the religion, and its cities panel lists `GetReligionsInCity()`, each with `Religion` and `Followers`. Before any religion, Rome's one entry had `Religion` -1 with 3 followers. Confirmed in files and on Windows on 2026-10-26.

## Method

1. To read a choice that the `.modinfo` doesn't load yet, send the code as in [game-choices.md](game-choices.md#method), step 6, then read `SentientSystems_GetChoices(Game.GetLocalPlayer())`.
2. To see the pantheon chooser, load a save from before a pantheon, send `Players[0]:GetReligion():ChangeFaithBalance(100)` in `GameCore_Tuner`, and end the turn.
3. To found a religion, in `GameCore_Tuner`, add a holy site with a shrine to Rome with `WorldBuilder.CityManager():CreateDistrict` and `CreateBuilding`, as in [game-choices.md](game-choices.md#method), step 3, create a Great Prophet with `Game.GetGreatPeople():CreatePerson`, and move it there with `UnitManager.PlaceUnit(unit, x, y)`. `CreateDistrict` does nothing when the city has no district slot left, so raise the population first with `city:ChangePopulation(3)`. Activate the prophet on the holy site.

## Results

A single-player game with Gathering Storm, on Rome's save, in `SentientSystemsCore_UI`:

| Check | Result |
| --- | --- |
| The choices on turn 14, with no pantheon and 100 faith from the tuner | No `pantheon` key, as `CanCreatePantheon()` was `false` |
| The choices on turn 15, with the same faith | 23 beliefs, from Dance of the Aurora to Fire Goddess, `BELIEF_GODDESS_OF_FIRE`, each with its description. No player had a pantheon yet. The chooser listed the same 23 in the same order, with the same text. `ENDTURN_BLOCKING_PANTHEON` was among the blockers. 3,046 bytes |
| The state after picking Religious Settlements on turn 15 | `{"pantheon":"BELIEF_RELIGIOUS_SETTLEMENTS","prophet":false}`, and `"prophet":true` once the tuner added a Great Prophet |
| The state on turn 16, after founding Catholicism with Feed the World and Gurdwara | `founded` with `RELIGION_CATHOLICISM`, `Catholicism`, both beliefs, holy city 65536, a majority in 1 city, and Rome with 4 followers. No `prophet`, as 2 beliefs were earned. The My Religion tab showed the same religion, Rome as its holy city, **Dominant religion in 1 city**, the two beliefs and two locked slots, and Rome with 4 followers |

Date checked: game files on 2026-10-26. Running game on Windows on 2026-10-26.
