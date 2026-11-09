# Action API: great works

Add the actions that move a great work between slots and that choose an artifact. The great work state comes first, so the agent knows where a work can go. Part of [phase 1](README.md).

## Tasks

1. **Move a great work.** Add an action that moves a great work from one slot to another slot of the same kind, in the same city or another. The action returns a reason when the slot doesn't take the work, such as a slot of another kind or one the player doesn't own.

   Read the calls from `GreatWorksOverview.lua`. Add the typed function to `src/actions/great-works.ts`. Commit: `feat(core): add the great work move action`.
2. **Artifacts.** Add an action that chooses an artifact, which becomes a great work in a slot. Read the call from `ChooseArtifact.lua`. Commit: `feat(core): add the artifact action`.

## Done when

In a running game, each action works once from the bridge, and each one returns a reason for one illegal case, such as a slot of another kind.

## Record

- Each request function, its Lua state, its result, and the setup that made its blocker appear, in a findings file of its own, with a row in the [findings index](../../findings/README.md).
- The reasons, in [design/core/mod/actions/README.md](../../design/core/mod/actions/README.md).
- The rows of each action, in the `## Parts of an action` table in the [core README](../../../packages/core/README.md).
