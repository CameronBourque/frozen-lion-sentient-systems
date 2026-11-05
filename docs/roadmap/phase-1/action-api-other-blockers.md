# Action API: other blockers

Add the actions for the remaining blockers: captured and disloyal cities, espionage, the World Congress and emergencies, and era dedications. The blockers are in [state/state.md](../../findings/state/state.md#end-turn-blockers). Part of [phase 1](README.md).

## Tasks

1. **City fate.** Add actions that keep or raze a captured city and that decide a disloyal city. Read the calls from `RazeCity.lua` and `DisloyalCityChooser.lua`. Commit: `feat(core): add the captured and disloyal city actions`.
2. **Espionage.** Add actions that choose an escape route and a dragnet priority. Read the calls from `EspionageEscape.lua`. Commit: `feat(core): add the espionage actions`.
3. **World Congress and emergencies.** Add actions that vote in a session, make a proposal, and answer an emergency. Read the calls from `WorldCongressPopup.lua` and `WorldCrisisPopup.lua`. Commit: `feat(core): add the World Congress and emergency actions`.
4. **Era dedications.** Add an action that chooses a dedication. Read the call from `EraReviewPopup.lua`. Commit: `feat(core): add the era dedication action`.

## Done when

In a running game, each action works once from the bridge, and each one returns a reason for one illegal case, such as a vote with too few favor or a dedication that isn't offered. An action whose blocker can't be set up in a test game is recorded as unconfirmed in its finding.

## Record

- Each request function, its Lua state, its result, and the setup that made its blocker appear, in a findings file of its own, with a row in the [findings index](../../findings/README.md).
- The reasons, in [design/core/mod/actions.md](../../design/core/mod/actions.md).
- The rows of each action, in the `## Parts of an action` table in the [core README](../../../packages/core/README.md).
