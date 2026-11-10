# Government actions

How the core mod runs the actions that set the policies in a government's slots, pay the unlock, and change the government. Part of the [action API](README.md).

## Policies

`SentientSystems_SetPolicies(playerID, slots)` in `Scripts/Actions/SentientSystemsCore_ActionsPolicies.lua` sets the policy in every slot, as the government screen's confirm does.

`slots` holds a policy type, or `false` for an empty slot, for each slot by its number in the `government` choice, from 0. Every slot must be listed, so a slot left out can't be emptied by mistake.

A policy is the `type` of a policy in the `policies` choice, or of one in a slot. A slotted policy can stay or move to another slot.

The game takes a policy in a slot of the wrong type, and a change at any time, so the action checks first. See [policies.md](../../../../findings/actions/policies.md).

`SentientSystems_GetPolicyChangeFailure` in `Scripts/SentientSystemsCore_Government.lua` gives the screen's rule for a change as a reason. The `canChange` of the `policies` choice is `true` when it gives none, so the choice and the action can't disagree.

Its reasons, in order, name a turn that isn't the player's, a change made this turn already, and a turn with no civic completed and no empty slot. The last one points at the unlock when the game offers one.

Then the reasons name a list that doesn't give every slot once, a type that is no policy, a policy the player can't slot, a policy in two slots, and a policy in a slot of another type. Last, a set that matches the slots is refused.

On the bridge, `setPolicies` in `src/actions/policies.ts` takes a list by slot number, with `null` for an empty slot.

## Unlock

`SentientSystems_UnlockPolicies(playerID)` in the same file pays the cost of the `unlock` in the `policies` and `governments` choices, as either unlock button does. It lets the player change policies and the government on a turn with no civic completed.

`SentientSystems_GetUnlock` in `Scripts/SentientSystemsCore_Government.lua` builds each choice's `unlock`, and the action reads its checks from it. So the action pays exactly when a choice shows the unlock as open.

Its reasons, in order, name a turn that isn't the player's, a policy change made this turn with no unlock in the `governments` choice, no unlock to pay for, a World Congress in session, and a cost the player can't afford.

On the bridge, `unlockPolicies` in `src/actions/policies.ts` takes only the player.

## Government

`SentientSystems_SetGovernment(playerID, government)` in the same file changes the government to a `type` from the `governments` choice, as the screen's confirm does.

`SentientSystems_GetGovernmentChangeFailure` in `Scripts/SentientSystemsCore_Government.lua` gives the screen's rule for a change as a reason, and the `canChange` of the `governments` choice is `true` when it gives none.

Its reasons, in order, name a turn that isn't the player's, a game that allows no change yet, a change made this turn already, and a turn with no civic completed. The last one points at the unlock when the `governments` choice shows one.

Then the reasons name a type that is no government, the current government, and a government that isn't unlocked. A change the game refuses gives a reason too.

On the bridge, `setGovernment` in `src/actions/policies.ts` takes the government's type.

## Decisions

| Decision | Reason |
| --- | --- |
| The action takes the policy for every slot, not a change to one slot | The screen sends every slot in one request, and a second request in a turn breaks the screen's rule. A move between slots needs both slots in one request |
| The action checks every slot before it sends anything | One wrong slot in a request still uses up the turn's change |
| The action follows the screen's rule for when a change is allowed | The game takes a change at any time, which a player can't make |
| A set that matches the slots is refused | A request marks the turn's change as made, so the agent would lose its change for nothing |
| The choice's `canChange` and the action share one function that returns the reason | The two can't disagree, and the reason comes with the check |
| The unlock action pays when either tab shows the unlock | One request opens both tabs, and after a policy change only the government tab still offers it |
| The unlock action and the choices' `unlock` share one function | The action pays only an unlock a choice shows as open |
| The government action refuses the current government | The screen allows the click, but a request would use up the turn's change for nothing |
| The government action changes the government even with anarchy turns | The `governments` choice gives each government's anarchy, so the agent chooses with it |
