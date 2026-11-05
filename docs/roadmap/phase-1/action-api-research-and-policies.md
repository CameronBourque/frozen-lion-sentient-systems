# Action API: research and policies

Add the actions for research, civics, policies, and a change of government. They resolve the research, civic, policy slot, and government change blockers. Part of [phase 1](README.md).

## Tasks

1. **Research and civic.** Add `SentientSystems_SetResearch(playerID, tech)` and `SentientSystems_SetCivic(playerID, civic)`. Read the calls from `ResearchChooser.lua` and `CivicsChooser.lua`. Add `setResearch` and `setCivic` to `src/actions/research.ts`. Commit: `feat(core): add research and civic actions`.
2. **Policies and government.** Add `SentientSystems_SetPolicies(playerID, slots)` and `SentientSystems_SetGovernment(playerID, government)`. Read the calls from `GovernmentScreen.lua`. Add `setPolicies` and `setGovernment` to `src/actions/policies.ts`. Commit: `feat(core): add policy and government actions`.

## Done when

In a running game, each action works once from the bridge, and each one returns a reason for one illegal case, such as a tech that isn't available yet or a policy in a slot of the wrong type.

## Record

- Each request function, its Lua state, and its result, in a findings file of its own, with a row in the [findings index](../../findings/README.md).
- The reasons, in [design/core/mod/actions.md](../../design/core/mod/actions.md).
- The rows of each action, in the `## Parts of an action` table in the [core README](../../../packages/core/README.md).
