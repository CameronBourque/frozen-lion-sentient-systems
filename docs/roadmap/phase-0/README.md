# Phase 0: Prove the bridge

Every later phase depends on the FireTuner channel, and its protocol is undocumented, so phase 0 proves it first.

**Gate.** From the bridge, list your cities and move one unit.

## Starting point

Repo setup is done, and core `0.1.0` tested the release flow. The bridge project is set up in `packages/core/bridge/`, and `build:exe` builds it into one executable. Local paths are in [findings/README.md](../../findings/README.md#local-paths). What the game files already show is in [findings/](../../findings/README.md). The gate confirmed that actions requested from the core mod's UI state take effect, so the action API can run there. See [lua-contexts.md](../../findings/lua-contexts.md#where-actions-can-come-from).

## Steps

| # | Step | Covers | Status |
| --- | --- | --- | --- |
| 1 | Create the findings folder | One file per research topic | Done. The step file is deleted, and the results are in [findings/](../../findings/README.md) |
| 2 | Turn on the tuner | Enable the tuner and run Lua from FireTuner | Done. The step file is deleted, and the results are in [tuner-setup.md](../../findings/tuner-setup.md#results), [tuner-protocol.md](../../findings/tuner-protocol.md#what-we-know-now), and [lua-contexts.md](../../findings/lua-contexts.md#results) |
| 3 | Capture the tuner protocol | Record the wire format from real traffic | Done. The step file is deleted, and the results are in [tuner-protocol.md](../../findings/tuner-protocol.md#results) |
| 4 | Scaffold the bridge project | TypeScript project in `packages/core/bridge/` | Done. The step file is deleted, and the choices are in [rules/code.md](../../rules/code.md#typescript) |
| 5 | Build the single executable | Add `build:exe` with Node SEA, and build it in the release | Done. The step file is deleted, and the results are in [build-tooling.md](../../findings/build-tooling.md#results) |
| 6 | Tuner client | Framing, connection, and protocol modules | Done. The step file is deleted, and the results are in [tuner-commands.md](../../findings/tuner-commands.md#results), [lua-contexts.md](../../findings/lua-contexts.md#state-list-over-a-session), and [bridge.md](../../design/core/bridge.md#decisions) |
| 7 | Minimal core mod | `.modinfo`, turn signal, version report, tag format | Done. The step file is deleted, and the results are in [lua-contexts.md](../../findings/lua-contexts.md#the-core-mods-states), [game-api.md](../../findings/game-api.md#mod-metadata), [multiplayer.md](../../findings/multiplayer.md#hotseat), and [in-game-lua.md](../../design/core/in-game-lua.md) |
| 8 | Receive the turn signal | Parse tagged lines into events in the bridge | Done. The step file is deleted, and the results are in [tuner-commands.md](../../findings/tuner-commands.md#behavior-notes) and [bridge.md](../../design/core/bridge.md) |
| 9 | Resync on connect | Recover the turn state after a bridge restart | Done. The step file is deleted, and the results are in [tuner-commands.md](../../findings/tuner-commands.md#behavior-notes), [game-api.md](../../findings/game-api.md#active-player), [lua-contexts.md](../../findings/lua-contexts.md#turn-events-differ-by-script-type), [tuner-protocol.md](../../findings/tuner-protocol.md#what-we-know-now), [bridge.md](../../design/core/bridge.md), and [in-game-lua.md](../../design/core/in-game-lua.md) |
| 10 | The gate | List cities and move a unit from the bridge | Done. The step file is deleted, and the results are in [game-api.md](../../findings/game-api.md#results), [lua-contexts.md](../../findings/lua-contexts.md#where-actions-can-come-from), and [tuner-setup.md](../../findings/tuner-setup.md#results) |
| 11 | [Online multiplayer check](11-online-multiplayer.md) | Read-only tuner test in an online game | |
| 12 | [Close out phase 0](12-close-out.md) | Update the docs and release core `0.1.0` | |

## Suggested PR breakdown

PR titles follow [rules/commits.md](../../rules/commits.md).

1. `chore: upgrade to node 26 and record bridge build decisions` (the choices for steps 4 and 5)
2. `chore(core): set up bridge workspace` (step 4)
3. `chore(core): build the bridge executable` (step 5)
4. `feat(core): add tuner client` (step 6). This triggers core `0.1.0`
5. `feat(core): add turn signal and resync` (steps 7 to 9)
6. `docs: record phase 0 results` (steps 10 to 12, with the gate script if you keep it)
