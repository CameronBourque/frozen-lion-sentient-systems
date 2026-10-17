# Step 10: The gate

List your cities and move a unit from the bridge. Write the gate as `src/scripts/gate.ts`. It's throwaway code, because [phase 1](../phase-1/README.md) builds the real action API. Part of [phase 0](README.md).

## Tasks

1. **List cities.** Use the city loop from [game-api.md](../../findings/game-api.md#cities) for `Game.GetLocalPlayer()`, and print `name, x, y, population` for each city. Run the loop in a gameplay state first, then in your UI state. Compare what each state sees.
2. **List units.** Loop over `Players[id]:GetUnits():Members()` and print `id, type, x, y, moves left`. You need a unit ID for the next task.
3. **Move a unit.** In your UI state, follow the move path in [game-api.md](../../findings/game-api.md#moving-a-unit):
   - get the unit with `UnitManager.GetUnit(playerID, unitID)`,
   - set the target to an adjacent passable tile,
   - print the result of `CanStartOperation`, then call `RequestOperation`,
   - read the unit's position again on the next call, because the move may complete asynchronously.
4. **Negative test.** Request a move into deep water for a land unit, and record what `CanStartOperation` returns. Phase 1 designs its failure reasons from this result.
5. **End the turn.** This task is optional. Run `UI.RequestAction(ActionTypes.ACTION_ENDTURN)`, and check that the next `AGENT_TURN` line arrives. Phase 1 runs this same loop every turn.
6. **SDK check.** This task is optional. Uninstall the SDK as step 6 of the [tuner setup method](../../findings/tuner-setup.md#method) describes, and run `gate.ts` again. Reinstall the SDK afterward, because FireTuner comes with it.

## Done when

The bridge prints your cities, and a unit visibly moves on the map. The gate has passed.

## Record

- Each call, its Lua state, and its result, in [game-api.md](../../findings/game-api.md#results-from-testing). The negative test answers question 4.
- Which state issued the action, in [lua-contexts.md](../../findings/lua-contexts.md#results), question 2. This answer decides where the action API runs.
- If you ran the SDK check, whether the tuner works without the SDK, in [tuner-setup.md](../../findings/tuner-setup.md#results), question 2.
