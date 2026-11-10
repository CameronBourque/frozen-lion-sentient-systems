# Policy and government actions

Status: confirmed. Setting the policies in every slot, paying the unlock, changing the government, and what the game takes and refuses, are confirmed in a running game with Gathering Storm.

The game calls that the policy and government actions wrap, with the Lua state they run in and what the game checks. The slots and the policies the player can slot are in [choices/government.md](../choices/government.md).

The core mod's result format is in [design/core/mod/actions/README.md](../../design/core/mod/actions/README.md). The other actions are in the [actions index](README.md).

## Questions

None.

## What we know now

### Setting the policies

`OnConfirmPolicies` in `Base/Assets/UI/Screens/GovernmentScreen.lua` calls `player:GetCulture():RequestPolicyChanges(clearList, addList)`. Confirmed in files.

- `clearList` lists every slot index, from 0, and `addList` holds the hash of each filled slot's policy, keyed by the slot index. So each confirm sends the whole set, and a policy can move between slots, because the game clears every slot before it adds any.
- The action runs in `SentientSystemsCore_UI`. The game handles the request a moment after the tuner command, as with the [research actions](research.md#setting-the-tech-or-the-civic).
- `IsSlotTypeLegalInRow` lets a row take a policy of its own slot type, and the wildcard row take any policy, because `m_isAllowAnythingInWildcardSlot` is `true`. A `SLOT_GREAT_PERSON` policy counts as a wildcard one.

  No expansion replaces the rule. Only `DLC/BlackDeathScenario` does. Confirmed in files.
- Gathering Storm's `IsReadOnly` only disables the unlock button while the World Congress is in session. The slots stay open to change. Confirmed in files.

### Paying the unlock

`OnUnlockPolicies` in `GovernmentScreen.lua` sends `UI.RequestPlayerOperation(Game.GetLocalPlayer(), PlayerOperations.UNLOCK_POLICIES, {})`. `OnUnlockGovernments` sends the same request, so one payment opens both tabs. Confirmed in files.

Paying it is the only way to change the government on a turn with no civic completed, because the payment sets `CivicCompletedThisTurn()` to `true`.

- The policies tab hides the button after a policy change this turn, or when `GetCostToUnlockPolicies()` is 0. It disables it when the player can't afford it, and in Gathering Storm while the World Congress is in session. See [choices/government.md](../choices/government.md#what-we-know-now).
- The View Governments tab hides its button after a change of government this turn, with no government, or with one government unlocked. See `RealizeGovernmentsPage`, lines 585 to 630.
- The action runs in `SentientSystemsCore_UI`, and pays when either tab shows the button.
- After the request, the gold balance dropped by the cost, `GetCostToUnlockPolicies()` returned 0, and `CivicCompletedThisTurn()` returned `true`, so the policies choice's `canChange` became `true`. Confirmed on Windows on 2026-11-09.

### Changing the government

`OnGovernmentSelected` in `GovernmentScreen.lua` opens a confirm popup when `IsAbleToChangeGovernment()` is `true`. Its confirm calls `player:GetCulture():RequestChangeGovernment(hash)`, which returns whether the game took it. No expansion replaces these. Confirmed in files.

- The popup warns of `GetAnarchyTurns(index)` turns of anarchy when there are any. The screen lets the player click the current government too.
- The action runs in `SentientSystemsCore_UI`. The change from Chiefdom to Oligarchy took effect at once, with no anarchy, and set `GovernmentChangeMade()` to `true`.
- The policies stayed in their slots of the same type. The new military and wildcard slots were empty, so `GetNumPolicySlotsOpen()` returned 2, and a policy change was still open that turn. Confirmed on Windows on 2026-11-09.

### The game's checks

- `CanSlotPolicy(hash, slot)` returned `true` for Discipline in the military slot and God King in the economic one. It returned `false` for Discipline in the economic slot and Charismatic Leader, a diplomatic policy, in the military one.

  Under Oligarchy, it returned `true` in the wildcard slot for a military, an economic, and a diplomatic policy, so the game's rule for the wildcard slot matches the screen's.

  It returned `false` for God King once God King was in a slot, as the screen's comment on `m_isAllowAnythingInWildcardSlot` says. It returned `true` for Ilkum in a slot that held another policy. It takes a hash or an index. Confirmed on Windows on 2026-11-09.
- A request with Charismatic Leader in the military slot and God King in the economic one slotted God King alone. It set `PolicyChangeMade()` to `true`, so one wrong slot uses up the turn's change.
- The game doesn't check `IsAbleToChangePolicies`. With `PolicyChangeMade()` `true`, an open slot, and no civic completed, a request filled the slot. With no open slot, a second request swapped both policies.
- So the action checks the screen's rule for a change and every slot's type before it sends a request.

## Method

1. Send the file's code to `SentientSystemsCore_UI` as in [choices/production.md](../choices/production.md#method), step 4. Send `Scripts/SentientSystemsCore_Government.lua` first, then the government choices and the policy actions files.
2. Call `setPolicies` from the bridge. Wait 1.5 seconds, then read each slot's `GetSlotPolicy(i)` and `PolicyChangeMade()`.
3. To allow a change on a turn with no civic completed, pay the unlock with `UI.RequestPlayerOperation(0, PlayerOperations.UNLOCK_POLICIES, {})`. It spends the gold.
4. To give the player gold for the unlock, in `GameCore_Tuner`, send `Players[0]:GetTreasury():ChangeGoldBalance(100)`.
5. To find an unlocked government, read the governments choice. On Rome's save, Autocracy, Oligarchy, and Classical Republic were unlocked by turn 18.
6. To see what the game takes, call `RequestPolicyChanges` with a policy in a slot of another type, or after a change this turn.

## Results

A single-player game with Gathering Storm, on Rome's save, in `SentientSystemsCore_UI`, for player 0, under Chiefdom, with slot 0 `SLOT_MILITARY` and slot 1 `SLOT_ECONOMIC`:

| Call | Result |
| --- | --- |
| `setPolicies(["POLICY_DISCIPLINE", "POLICY_GOD_KING"])` on turn 16, after a change | `You changed policies this turn already.` |
| The same on turn 17, with no civic completed and no open slot | The reason, and that the unlock pays for a change. The policies choice showed an unlock for 90 gold |
| `setPolicies(["POLICY_CHARISMATIC_LEADER", "POLICY_GOD_KING"])`, after the unlock | `Slot 0 is a SLOT_MILITARY slot, which can't hold POLICY_CHARISMATIC_LEADER, a SLOT_DIPLOMATIC policy.` `PolicyChangeMade()` stayed `false` |
| `setPolicies(["POLICY_SURVEY", "POLICY_ILKUM"])`, the policies in the slots | `Your slots hold those policies already.` |
| `setPolicies(["POLICY_DISCIPLINE"])` | The reason that names the 2 slots |
| `setPolicies(["POLICY_DISCIPLINE", "POLICY_GOD_KING"])` | `{"ok":true}`. The slots held Discipline and God King, and `canChange` became `false` |
| `unlockPolicies(0)` on turn 17, after the change | `You changed policies this turn already.` |
| `unlockPolicies(0)` on turn 18, with 46 gold and a cost of 90 | `You can't afford the unlock's 90 gold.` |
| `unlockPolicies(0)`, after 100 gold was added | `{"ok":true}`. The gold went from 146 to 56, the cost to 0, and `canChange` became `true` |
| `unlockPolicies(0)` again | `There's no unlock to pay for now.` |
| `setGovernment(0, "GOVERNMENT_MONARCHY")` | `GOVERNMENT_MONARCHY isn't unlocked yet. The governments choice gives the civic it needs.` |
| `setGovernment(0, "GOVERNMENT_CHIEFDOM")` | `GOVERNMENT_CHIEFDOM is your government already.` |
| `setGovernment(0, "GOVERNMENT_OLIGARCHY")`, after the unlock | `{"ok":true}`. Oligarchy took effect, with slots `SLOT_MILITARY`, `SLOT_MILITARY`, `SLOT_ECONOMIC`, and `SLOT_WILDCARD`, and Discipline and God King kept |
| `setGovernment(0, "GOVERNMENT_AUTOCRACY")` | `You changed governments this turn already.` |
| `setPolicies(["POLICY_DISCIPLINE", "POLICY_SURVEY", "POLICY_GOD_KING", "POLICY_CHARISMATIC_LEADER"])` | `{"ok":true}`. The wildcard slot held Charismatic Leader |

Date checked: 2026-11-09.
