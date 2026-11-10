# Action API: research and policies

Add the actions for research, civics, policies, the paid policy unlock, and a change of government. They resolve the research, civic, policy slot, and government change blockers. Part of [phase 1](README.md).

## Tasks

1. **Research and civic.** Add `SentientSystems_SetResearch(playerID, tech)` and `SentientSystems_SetCivic(playerID, civic)`, which take a tech or civic from the choice.

   Both send the chooser's call, `UI.RequestPlayerOperation` with `RESEARCH` or `PROGRESS_CIVIC` and `VALUE_EXCLUSIVE`, from `ResearchChooser.lua` and `CivicsChooser.lua`.

   Move the `KINDS` table out of `SentientSystemsCore_ChoicesResearch.lua` into a shared file, and add each kind's operation and parameter key. One action reads the table, and each public function is a one-line wrapper.

   Add one helper to `src/actions/research.ts` that builds `setResearch` and `setCivic`. Commit: `feat(core): add research and civic actions`.
2. **Queuing.** Let both actions take a later tech or civic, and append it to the queue. The tree screens send the path from `GetResearchPath(hash)`, with `VALUE_APPEND` on shift-click. See `SetCurrentNode` in `TechTree.lua` and `CivicsTree.lua`.

   Add the path and the append flag to the shared action and the shared helper, not new actions. Add the queue to the tech and civic choices. Commit: `feat(core): add research and civic queuing`.
3. **Policies.** Add `SentientSystems_SetPolicies(playerID, slots)`, where `slots` gives the policy each slot holds after the change, or none. The action works out the clear and add lists for `RequestPolicyChanges(clearList, addList)` from `OnConfirmPolicies` in `GovernmentScreen.lua`.

   Move the `canChange` checks out of `SentientSystemsCore_ChoicesGovernment.lua` into named functions that the choice and the action share. Add `setPolicies` to `src/actions/policies.ts`. Commit: `feat(core): add the policy action`.
4. **Paid policy unlock.** Add `SentientSystems_UnlockPolicies(playerID)`, which sends `PlayerOperations.UNLOCK_POLICIES`, as the unlock button does. Its checks reuse `GetUnlock` from the government choices.

   Add `unlockPolicies` to `src/actions/policies.ts`. Commit: `feat(core): add the policy unlock action`.
5. **Government.** Add `SentientSystems_SetGovernment(playerID, government)`, which calls `RequestChangeGovernment(hash)` from `OnGovernmentSelected` in `GovernmentScreen.lua`. It shares the checks from the policies task, and the unlock from the paid policy unlock task.

   Add `setGovernment` to `src/actions/policies.ts`. Commit: `feat(core): add the government action`.

## Done when

In a running game, each action works once from the bridge, and each one returns a reason for one illegal case, such as a tech that isn't available yet, a policy in a slot of the wrong type, or an unlock the player can't afford. A queued tech or civic starts after the current one completes.

## Record

- Each request function, its Lua state, and its result, in a findings file of its own, with a row in the [findings index](../../findings/README.md).
- The reasons, in [design/core/mod/actions/research.md](../../design/core/mod/actions/research.md) and [government.md](../../design/core/mod/actions/government.md).
- The rows of each action, in the `## Parts of an action` table in the [core README](../../../packages/core/README.md).
