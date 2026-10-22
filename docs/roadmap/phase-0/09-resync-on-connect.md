# Step 9: Resync on connect

Make a bridge restart in the middle of a turn recover the turn state, as [design/core/bridge.md](../../design/core/bridge.md) requires. Part of [phase 0](README.md).

## Tasks

1. Add a core mod function `SentientSystems_Resync()` that prints the same `AGENT_TURN` line for the active player.
2. Print the UI script's load line with `SentientSystems_Print`, as `CORE_LOADED <context>`. Add the `CORE_LOADED` kind to `src/events.ts`.
3. When the bridge connects, it lists states, finds the core mod's state, calls `SentientSystems_GetVersion()`, and then calls `SentientSystems_Resync()`.
4. To test, start the bridge in the middle of your turn. Check that it logs `turn 0` without ending a turn.
5. Stop the bridge, restart it, and check that it logs `turn 0` again.
6. Make the version check only log the version for now. [Phase 4](../phase-4/README.md) adds mismatch handling and self-update.

## Done when

A restart in the middle of a turn recovers the turn state.

## Record

Which call returns the active player in single player and in hotseat, in [game-api.md](../../findings/game-api.md#questions), question 6. Phase 2 needs the hotseat answer.
