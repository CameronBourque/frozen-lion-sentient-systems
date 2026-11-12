# Action API: nuclear strikes

Add the nuclear and thermonuclear strike, the stockpile that feeds it, and the fallout it leaves. The attack action has no nuclear case, so an agent with a bomb can't use it, and nothing shows fallout or clears it. Part of [phase 1](README.md).

## Tasks

1. **Stockpile.** Add the player's nuclear and thermonuclear devices to the player section, and a `wmdLaunchers` section with the units and missile silos that can launch each device now.

   Read the calls from `TopPanel.lua`, which lists `GameInfo.WMDs()` against `Players[id]:GetWMDs()`, from `UnitPanel.lua`, and from the silo banner in `CityBannerManager.lua`.

   A silo fires through its city, the one `Cities.GetPlotPurchaseCity` gives. Commit: `feat(core): add the nuclear stockpile to the state`.
2. **Strike.** Add an action that launches a device at a tile from a unit or a silo, with the device type, and lists the tiles in range when the tile isn't a target.

   Read the calls from the WMD and ICBM strike modes of `WorldInput.lua`. A unit uses `UnitOperationTypes.WMD_STRIKE` with `PARAM_WMD_TYPE` and its targets from `UnitManager.GetOperationTargets`.

   A silo uses `CityCommandTypes.WMD_STRIKE` with the silo as `PARAM_X0` and `PARAM_Y0`, and its targets from `CityManager.GetCommandTargets`. Both take the war check from `CombatManager.IsAttackChangeWarState`.

   Answer question 1 of [findings/state/wmds.md](../../findings/state/wmds.md#questions), whether a unit with no moves left can launch. Commit: `feat(core): add the nuclear strike action`.
3. **Fallout.** Add the turns of fallout left to each tile that has it, and an action that clears it. Read the turns from `Game.GetFalloutManager():GetFalloutTurnsRemaining(plotIndex)`, as `PlotToolTip.lua` does.

   The strike of task 2 leaves the fallout to test with.

   The clear is `UNITOPERATION_CLEAR_CONTAMINATION`, a plain unit operation in the `SPECIFIC` category. Find out which units can do it, such as a builder or a unit of Rome. Commit: `feat(core): add fallout to the state and the clear fallout action`.

## Done when

In a running game, the action launches a nuclear device and a thermonuclear device once each from the bridge, from a unit and from a silo.

It returns a reason for an illegal tile, such as one out of range or one that would start a war. A strike that changes war state is refused as the move and attack actions are.

The state shows the fallout the strike leaves with its turns left, and the clear action clears one tile once, with a reason for a unit that can't.

## Record

- The stockpile and the launchers, in [findings/state/wmds.md](../../findings/state/wmds.md), and the fallout in a findings file of its own in [findings/state/](../../findings/state/README.md).
- Each request function, its Lua state, its result, and the setup that gave the player a device, in a findings file of its own in [findings/actions/](../../findings/actions/README.md), with a row in its index. A device can be spawned with `UnitManager.InitUnit` in the tuner.
- The stockpile, the launchers, and the fallout, in [design/core/mod/state.md](../../design/core/mod/state.md), and the strike, the clear action, and their reasons, in [design/core/mod/actions/README.md](../../design/core/mod/actions/README.md).
- The rows of the action, in the `## Parts of an action` table in the [core README](../../../packages/core/README.md), and of the state sections, in its `## Parts of a state section` table.
