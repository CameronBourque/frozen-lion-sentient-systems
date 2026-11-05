# Action API: unit jobs

Add the unit orders that the unit actions leave out and that need no choice first: builder jobs, upgrades, formations, and air movement. Each adds its orders to `SentientSystems_UnitAction` in its own Lua file under `Scripts/Actions/`, as the stances and the tile orders do. Part of [phase 1](README.md).

## Tasks

1. **Builder jobs.** Add `build_road`, `remove_feature`, `harvest`, `repair`, and `remove_improvement`, which act on the unit's own tile like `improve`. Read the operations from `UnitPanel.lua`, and let `type` name the route for a road. The game gives no reasons, so work them out from the unit and the tile, as `found_city` does. Add the orders to `UnitOrder` in `src/actions/units.ts`. Commit: `feat(core): add the builder job actions`.
2. **Upgrade.** Add `upgrade`, from the upgrade command in `UnitPanel.lua`. Read the unit it becomes, the gold it costs, and the resources it needs, and return the shortfall as the reason. Commit: `feat(core): add the upgrade action`.
3. **Formations.** Add `form_corps`, `form_army`, `enter_formation`, and `exit_formation`. Read the calls from `UnitPanel.lua` and `WorldInput.lua`, including `OnUnitActionClicked_EnterFormation`, which names the other unit. Commit: `feat(core): add the formation actions`.
4. **Air movement.** Add `rebase` and `deploy` for air units, and `airlift` and `paradrop` for land units, which name a target tile in `x` and `y`. Return a reason when the tile is out of range, and make the move action's reason for an air unit name these. Commit: `feat(core): add the air movement actions`.
5. **Priority target.** Add `priority_target`, which names a tile in `x` and `y` and hits the support or civilian unit that a military unit escorts. Read the command from `WorldInput_Expansion1.lua`, and return a reason when the tile has none. Commit: `feat(core): add the priority target action`.
6. **Add production.** Add `add_production`, from the unit commands that add production to a city's item at the cost of a build charge, for a military engineer or builder in a city. Return a reason when the unit isn't in a city or the city builds nothing it can help. Commit: `feat(core): add the production action`.

## Done when

In a running game, each order works once from the bridge. It also returns a reason for one illegal case: a road on a tile that has one, an upgrade without enough gold, a formation of units that can't join, and a rebase to a tile out of range.

## Record

- Each request function, its Lua state, and its result, in `findings/actions/unit-orders.md`. Start a second findings file if it passes 150 lines.
- The reasons, in [in-game-lua.md](../../design/core/in-game-lua.md).
- The rows of each order, in the `## Parts of an action` table in the [core README](../../../packages/core/README.md).
