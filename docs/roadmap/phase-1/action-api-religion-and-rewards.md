# Action API: religion and rewards

Add the actions for the pantheon, great person, religion, governor, and envoy blockers. Each blocker needs its own setup in a game, so each one is its own task. The tasks run in the order each one sets up the next. Part of [phase 1](README.md).

## Tasks

1. **Pantheon.** Add an action that founds a pantheon with one belief. Read the call from `PantheonChooser.lua`, as [findings/choices/religion.md](../../findings/choices/religion.md#pantheon) describes. Add the typed function to `packages/core/bridge/src/actions/religion.ts`. Commit: `feat(core): add the pantheon action`.
2. **Great people.** Add actions that recruit, pass, and patronize a great person. Read the calls from `GreatPeoplePopup.lua`. Claim a Great Prophet to set up the next task. Commit: `feat(core): add the great person actions`.
3. **Found a religion.** Add an action that founds a religion with its name and its two starting beliefs, as `ReligionScreen.lua` sends them. Check that the first belief is a follower belief and the second is from another class. Commit: `feat(core): add the found religion action`.
4. **Apostle orders.** Add the Apostle's `evangelize_belief` and `launch_inquisition` unit orders, which the religious units step left out. Commit: `feat(core): add the evangelize and inquisition unit orders`.
5. **Add a belief.** Add an action that adds one belief to a founded religion, after an Apostle evangelizes. Check that the religion has a belief pick left and has no belief of that class. Commit: `feat(core): add the belief action`.
6. **Governors.** Add actions for appointing a governor, taking an opportunity, promoting, and assigning an idle governor. Read the calls from `GovernorPanel.lua`. Commit: `feat(core): add the governor actions`.
7. **Envoys.** Add an action that gives an influence token to a city-state. Read the call from the envoys view of `CityStates.lua`. Test it in a save of its own with a met city-state, along with the governor actions the first save can't reach. Commit: `feat(core): add the envoy action`.

## Done when

In a running game, each action works once from the bridge, and each one returns a reason for one illegal case, such as a belief that isn't available or a city-state that isn't met.

## Record

- Each request function, its Lua state, its result, and the setup that made its blocker appear, in a findings file of its own, with a row in the [findings index](../../findings/README.md).
- The reasons, in [design/core/mod/actions/README.md](../../design/core/mod/actions/README.md).
- The rows of each action, in the `## Parts of an action` table in the [core README](../../../packages/core/README.md).
