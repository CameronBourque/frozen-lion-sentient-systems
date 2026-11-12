# WMD strike actions

Status: unconfirmed. The calls are confirmed in the game files. The strike from a unit and from a silo isn't tested in a running game yet.

The game calls that the unit's `wmd_strike` order and `SentientSystems_SiloStrike` wrap, with the Lua state they run in and what the game checks. What can launch each device is in [state/wmds.md](../state/wmds.md).

The core mod's result format is in [design/core/mod/actions/README.md](../../design/core/mod/actions/README.md). The other actions are in the [actions index](README.md).

## Questions

1. Does the strike request take effect from `SentientSystemsCore_UI`, from a unit and from a silo?
2. Does `CombatManager.IsAttackChangeWarState` with the device name every player whose tiles the blast reaches, or only the target tile's owner?

## What we know now

### From a unit

`OnWMDStrikeEnd` in `Base/Assets/UI/WorldInput.lua` checks `UnitManager.CanStartOperation(unit, UnitOperationTypes.WMD_STRIKE, nil, parameters)`. The parameters hold the target in `PARAM_X` and `PARAM_Y` and the device's `GameInfo.WMDs` index in `PARAM_WMD_TYPE`.

`WMDStrike` then sends `UnitManager.RequestOperation(unit, UnitOperationTypes.WMD_STRIKE, parameters)`. No DLC replaces either function. Confirmed in files.

`OnInterfaceModeChange_WMD_Strike` marks every plot of `UnitManager.GetOperationTargets(unit, UnitOperationTypes.WMD_STRIKE, parameters)` as a target, with only the device in the parameters. Confirmed in files.

### From a missile silo

`OnICBMStrikeEnd` in the same file checks `CityManager.CanStartCommand(city, CityCommandTypes.WMD_STRIKE, parameters)`, and `ICBMStrike` sends `CityManager.RequestCommand` with the same parameters.

The parameters hold the silo in `PARAM_X0` and `PARAM_Y0`, the target in `PARAM_X1` and `PARAM_Y1`, and the device in `PARAM_WMD_TYPE`. The city is the one that owns the silo's tile. Confirmed in files.

`OnInterfaceModeChange_ICBM_Strike` marks every plot of `CityManager.GetCommandTargets(city, CityCommandTypes.WMD_STRIKE, parameters)`, with the device and the silo in the parameters. Confirmed in files.

### War

Both strikes call `CombatManager.IsAttackChangeWarState(componentID, x, y, wmdIndex)`, with the unit's or the city's component ID.

A non-empty list opens the surprise war dialog. Otherwise the UI asks to confirm the launch. Neither dialog has a call to answer, so the action refuses a strike that would start a war. Confirmed in files.

## Method

Not run yet.

## Results

None yet.

Date checked: game files on 2026-11-11.
