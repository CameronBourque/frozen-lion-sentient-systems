# Step 10: The gate

List your cities and move a unit from the bridge. Write the gate as `src/scripts/gate.ts`. It's throwaway code, because [phase 1](../phase-1/README.md) builds the real action API. Part of [phase 0](README.md).

## Tasks

1. From `gate.ts`, run steps 1 to 4 of the [game API method](../../findings/game-api.md#method). Use your UI state wherever the method says a UI state.
2. **End the turn.** This task is optional. Run step 5 of the [game API method](../../findings/game-api.md#method). Phase 1 runs this same loop every turn.
3. **SDK check.** This task is optional. Uninstall the SDK as step 5 of the [tuner setup method](../../findings/tuner-setup.md#method) describes, and run `gate.ts` again. Reinstall the SDK afterward, because FireTuner comes with it.

## Done when

The bridge prints your cities, and a unit visibly moves on the map. The gate has passed.

## Record

- Each call, its Lua state, and its result, in [game-api.md](../../findings/game-api.md#results). The negative test answers question 4.
- Which state issued the action, in [lua-contexts.md](../../findings/lua-contexts.md#results), question 1. This answer decides where the action API runs.
- If you ran the SDK check, whether the tuner works without the SDK, in [tuner-setup.md](../../findings/tuner-setup.md#results), question 1.
