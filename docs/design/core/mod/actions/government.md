# Policy actions

How the core mod runs the actions that set the policies in a government's slots and pay the unlock. Part of the [action API](README.md).

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

`SentientSystems_UnlockPolicies(playerID)` in the same file pays the cost of the `policies` choice's `unlock`, as the unlock button does. It lets the player change policies on a turn with no civic completed.

`SentientSystems_GetUnlock` in `Scripts/SentientSystemsCore_Government.lua` builds the choice's `unlock`, and the action reads its checks from it. So the action takes the unlock exactly when the choice shows it as open.

Its reasons, in order, name a turn that isn't the player's, a policy change made this turn already, no unlock to pay for, a World Congress in session, and a cost the player can't afford.

On the bridge, `unlockPolicies` in `src/actions/policies.ts` takes only the player.

## Decisions

| Decision | Reason |
| --- | --- |
| The action takes the policy for every slot, not a change to one slot | The screen sends every slot in one request, and a second request in a turn breaks the screen's rule. A move between slots needs both slots in one request |
| The action checks every slot before it sends anything | One wrong slot in a request still uses up the turn's change |
| The action follows the screen's rule for when a change is allowed | The game takes a change at any time, which a player can't make |
| A set that matches the slots is refused | A request marks the turn's change as made, so the agent would lose its change for nothing |
| The choice's `canChange` and the action share one function that returns the reason | The two can't disagree, and the reason comes with the check |
| The unlock action follows the policies tab, which hides the unlock after a policy change this turn | The government tab's own rule comes with the government action |
| The unlock action and the choice's `unlock` share one function | The action pays only an unlock the choice shows as open |
