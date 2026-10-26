# Game government

Status: open. The `government` and `policies` keys of `SentientSystems_GetChoices`, the player's government with its policy slots and the policies the player can slot, are confirmed in a running game.

The calls the government and policy choices use, as the government screen shows them. The other choices are in [game-choices.md](game-choices.md). See [in-game-lua.md](../design/core/in-game-lua.md).

## Questions

None open.

## What we know now

`Base/Assets/UI/Screens/GovernmentScreen.lua` draws the government screen. `GovernmentScreen_Expansion1.lua` in `DLC/Expansion1` and `DLC/Expansion2` adds the dark age policies, and `GovernmentScreen_Expansion2.lua` leaves banned and unslottable policies out of the catalog, adds favor to each government's stats, and makes the screen read-only while the World Congress is in session. None of them changes the current government or its slots. Confirmed in files.

- **Current government.** `PopulateLivePlayerData`, lines 2235 to 2346, reads `player:GetCulture():GetCurrentGovernment()`, an index in `GameInfo.Governments`, which is -1 for no government. Rome's save on turn 15 gave 0, `GOVERNMENT_CHIEFDOM`. Confirmed in files and on Windows on 2026-10-26.
- **Slots.** The same function reads each slot from 0 to `GetNumPolicySlots() - 1`: `GetSlotType(i)`, an index in `GameInfo.GovernmentSlots`, such as `SLOT_MILITARY`, and `GetSlotPolicy(i)`, an index in `GameInfo.Policies`, which is -1 for an empty slot. The screen puts each slot in the row its type names, and `SLOT_GREAT_PERSON` in the wildcard row. `RequestPolicyChanges(clearList, addList)`, in `OnConfirmPolicies`, lines 1538 to 1584, takes these slot indexes. Confirmed in files and on Windows on 2026-10-26.
- **Policy catalog.** `RealizePolicyCatalog`, lines 1057 to 1119, shows each row of `GameInfo.Policies()` that `IsPolicyAvailable` allows and that isn't in a slot, which `IsPolicyActive(hash)` on the culture tells. The base `IsPolicyAvailable`, lines 2224 to 2229, needs `IsPolicyUnlocked(hash)` and not `IsPolicyObsolete(hash)`. Gathering Storm's needs not `IsPolicyBanned(hash)`, `CanPolicyBeSlotted(hash)`, and not `IsPolicyObsolete(hash)`. `SortPolicies`, lines 2380 to 2390, orders the catalog by slot type, then by type. `IsSlotTypeLegalInRow`, lines 234 to 240, lets a row take a policy of its own slot type, and the wildcard row take any policy. A `SLOT_GREAT_PERSON` policy counts as a wildcard one, so only the wildcard row takes it. Confirmed in files and on Windows on 2026-10-26.
- **New.** `PopulateLivePlayerData`, lines 2257 to 2276, marks a policy as new when its `PrereqCivic` is the civic from `GetCivicCompletedThisTurn()`. Rise and Fall's replacement also marks its dark age policies at the start of a dark age, which the choices don't follow. Confirmed in files.
- **Changing policies.** `IsAbleToChangePolicies`, lines 842 to 853, is `true` when `CivicCompletedThisTurn()` is `true` or `GetNumPolicySlotsOpen()` is above 0, `Game.IsAllowStrategicCommands(playerID)` is `true`, and `PolicyChangeMade()` is `false`. Confirmed in files and on Windows on 2026-10-26.
- **Paying to change.** `RealizeActivePoliciesRows`, lines 1380 to 1428, shows **Unlock for 50 [ICON_GoldLarge] Gold**, from `LOC_GOVT_UNLOCK_GOLD`, when `GetCostToUnlockPolicies()` is above 0 and `PolicyChangeMade()` is `false`. It disables the button with `LOC_GOVT_NEED_GOLD` when the gold balance is below the cost, and uses faith and the `_FAITH` keys when `GlobalParameters.GOVERNMENT_UNLOCK_WITH_FAITH` isn't 0. Gathering Storm's `IsReadOnly` disables it while the World Congress is in session. The button sends `PlayerOperations.UNLOCK_POLICIES`. After it, `CivicCompletedThisTurn()` returned `true`, `GetCivicCompletedThisTurn()` -1, and the cost 0. Confirmed in files and on Windows on 2026-10-26.

## Method

1. To read a choice that the `.modinfo` doesn't load yet, send the code as in [game-choices.md](game-choices.md#method), step 6, then read `SentientSystems_GetChoices(Game.GetLocalPlayer())`.
2. To see empty and filled slots, complete a civic, read the choices, then slot policies in the government screen, confirm, and read them again.
3. To see the paid unlock, end the turn after a policy change. On a turn with no civic completed, the policies tab offers the unlock. Clicking it spends the gold, so reload the save afterwards.

## Results

A single-player game with Gathering Storm, on Rome's save, in `SentientSystemsCore_UI`:

| Check | Result |
| --- | --- |
| The government on Rome's save on turn 15, with Code of Laws researched that turn | Chiefdom, with slot 0 `SLOT_MILITARY` and slot 1 `SLOT_ECONOMIC`, both empty. `GetNumPolicySlotsOpen()` returned 2 and `CivicCompletedThisTurn()` `true`. Every other government was locked |
| The same, after slotting Discipline and God King in the government screen and confirming | Slot 0 had `POLICY_DISCIPLINE` and slot 1 `POLICY_GOD_KING`, as the My Government tab showed them under **Military Policies** and **Economic Policies**. `GetNumPolicySlotsOpen()` then returned 0 and `PolicyChangeMade()` `true` |
| Policies on turn 19, with Craftsmanship and Foreign Trade researched and 145 gold | `canChange` `false` and an unlock for 50 gold. Agoge, Maritime Industries, and Survey under `SLOT_MILITARY`, and Caravansaries, Ilkum, and Urban Planning under `SLOT_ECONOMIC`, each with its card's text. `GetCostToUnlockPolicies()` returned 50 and `PolicyChangeMade()` `false`. The policies tab showed the same six cards and **Unlock for 50 [ICON_GoldLarge] Gold**. After clicking it, `canChange` was `true` with no unlock, the same six policies, and 95 gold, and the tab became **Change Policies**, with **Assign All Policies** in place of the button |

Date checked: game files on 2026-10-26. Running game on Windows on 2026-10-26.
