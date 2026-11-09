# Action API: religion and rewards

Add the actions for the pantheon, religion, governor, envoy, and great person blockers. Each blocker needs its own setup in a game, so each one is its own task. Part of [phase 1](README.md).

## Tasks

1. **Religion.** Add actions for the pantheon, for founding a religion, and for choosing a belief. Read the calls from `PantheonChooser.lua` and `ReligionScreen.lua`. Add the typed functions to `src/actions/religion.ts`. Commit: `feat(core): add the religion actions`.
2. **Governors.** Add actions for appointing a governor, taking an opportunity, promoting, and assigning an idle governor. Read the calls from `GovernorPanel.lua`. Commit: `feat(core): add the governor actions`.
3. **Envoys.** Add an action that gives an influence token to a city-state. Read the call from the envoys view of `CityStates.lua`. Commit: `feat(core): add the envoy action`.
4. **Great people.** Add an action that claims a great person. Read the call from `GreatPeoplePopup.lua`. Commit: `feat(core): add the great person action`.

## Done when

In a running game, each action works once from the bridge, and each one returns a reason for one illegal case, such as a belief that isn't available or a city-state that isn't met.

## Record

- Each request function, its Lua state, its result, and the setup that made its blocker appear, in a findings file of its own, with a row in the [findings index](../../findings/README.md).
- The reasons, in [design/core/mod/actions/README.md](../../design/core/mod/actions/README.md).
- The rows of each action, in the `## Parts of an action` table in the [core README](../../../packages/core/README.md).
