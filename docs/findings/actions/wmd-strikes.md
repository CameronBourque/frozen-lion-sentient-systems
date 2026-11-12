# WMD strike actions

Status: confirmed. Strikes of both devices from units and from a missile silo, and the action's refusals, are confirmed in a running game with Gathering Storm, with the files sent through the tuner.

The game calls that the unit's `wmd_strike` order and `SentientSystems_SiloStrike` wrap, with the Lua state they run in and what the game checks. What can launch each device is in [state/wmds.md](../state/wmds.md).

The core mod's result format is in [design/core/mod/actions/README.md](../../design/core/mod/actions/README.md). The other actions are in the [actions index](README.md).

## Questions

None open.

## What we know now

### From a unit

`OnWMDStrikeEnd` in `Base/Assets/UI/WorldInput.lua` checks `UnitManager.CanStartOperation(unit, UnitOperationTypes.WMD_STRIKE, nil, parameters)`. The parameters hold the target in `PARAM_X` and `PARAM_Y` and the device's `GameInfo.WMDs` index in `PARAM_WMD_TYPE`.

`WMDStrike` then sends `UnitManager.RequestOperation(unit, UnitOperationTypes.WMD_STRIKE, parameters)`. No DLC replaces either function. Confirmed in files.

`OnInterfaceModeChange_WMD_Strike` marks every plot of `UnitManager.GetOperationTargets(unit, UnitOperationTypes.WMD_STRIKE, parameters)` as a target, with only the device in the parameters. Confirmed in files.

The request works from `SentientSystemsCore_UI`. A unit that strikes has 0 moves and 0 attacks left after it. Confirmed on Windows on 2026-11-11.

### From a missile silo

`OnICBMStrikeEnd` in the same file checks `CityManager.CanStartCommand(city, CityCommandTypes.WMD_STRIKE, parameters)`, and `ICBMStrike` sends `CityManager.RequestCommand` with the same parameters.

The parameters hold the silo in `PARAM_X0` and `PARAM_Y0`, the target in `PARAM_X1` and `PARAM_Y1`, and the device in `PARAM_WMD_TYPE`. The city is the one that owns the silo's tile. Confirmed in files.

`OnInterfaceModeChange_ICBM_Strike` marks every plot of `CityManager.GetCommandTargets(city, CityCommandTypes.WMD_STRIKE, parameters)`, with the device and the silo in the parameters. Confirmed in files.

The request works from `SentientSystemsCore_UI`. A silo fired twice in one turn, and it stayed ready for both devices after. Confirmed on Windows on 2026-11-11.

### When a strike lands

The request returns at once, and the strike takes effect after its animation. The stockpile, the fallout, and the population hadn't changed 4 or 12 seconds after a request, and had changed by 25 seconds. A caller that reads the result must wait for it. Confirmed on Windows on 2026-11-11.

### War

Both strikes call `CombatManager.IsAttackChangeWarState(componentID, x, y, wmdIndex)`, with the unit's or the city's component ID.

A non-empty list opens the surprise war dialog. Otherwise the UI asks to confirm the launch. Neither dialog has a call to answer, so the action refuses a strike that would start a war. Confirmed in files.

The check covers the blast, not only the target tile. For the same jet bomber, 9 tiles that Vietnam owns would start a war with a nuclear device, and 27 with a thermonuclear one, whose blast is larger. Confirmed on Windows on 2026-11-11.

## Method

1. Send `Scripts/SentientSystemsCore_Wmds.lua`, `Scripts/State/SentientSystemsCore_StateWmdLaunchers.lua`, and `Scripts/Actions/SentientSystemsCore_ActionsWmds.lua` to `SentientSystemsCore_UI`, each without its comments and `include` lines.
2. Load a save at war with a major, with devices and launchers. To find the tiles to hit, list each launcher's targets that the enemy owns, and keep those where `IsAttackChangeWarState` with the device returns an empty list.
3. Call `unitAction` with `wmd_strike` and `siloStrike` from the bridge. Wait 25 seconds, then read the stockpile, `GetFalloutTurnsRemaining` of the target, and the city's population.

## Results

A single-player game with Gathering Storm, player 0 at war with Vietnam, player 10, with 3 nuclear and 4 thermonuclear devices. Each strike returned `{"ok":true}`:

| Launcher | Device | Target | Result |
| --- | --- | --- | --- |
| Silo at (44, 30) | Nuclear | Đồng Hới, (37, 28), on a tile the player didn't see | Population 9 to 6, 10 turns of fallout |
| Jet bomber 14024845 | Thermonuclear | Thăng Long, (36, 36) | Population 14 to 1, 20 turns of fallout |
| Bomber 14090382 | Nuclear | (31, 37), beside Hội An | Hội An's population 5 to 3, 10 turns of fallout |
| Nuclear submarine 16056482 | Thermonuclear | Hong Kong, (33, 29) | Population 10 to 3, 20 turns of fallout |
| The same silo again | Thermonuclear | Trà Kiệu, (37, 32) | Population 7 to 1, 20 turns of fallout |

Afterwards the stockpile was 1 of each, and `wmdLaunchers` listed only the silo, for both devices.

The refusals, through the bridge:

| Call | Result |
| --- | --- |
| `wmd_strike` with `WMD_DIRTY_BOMB` | `WMD_DIRTY_BOMB isn't a device. The devices are WMD_NUCLEAR_DEVICE, WMD_THERMONUCLEAR_DEVICE.` |
| `wmd_strike` from a jet bomber with 0 moves | `The unit has no moves left.` |
| `wmd_strike` from the bomber at (70, 10) | `That tile isn't a target. It can hit 324 tiles, up to 10 tiles away.` |
| `wmd_strike` at (40, 31), a city-state's tile | `Striking there would start a war with player 25.` |
| `wmd_strike` from an aircraft carrier | `This unit can't launch Nuclear Device.` The game gave no reasons |
| `siloStrike` from (45, 30), a farm | `You have no missile silo at (45, 30).` |
| `siloStrike` at (70, 10) | `That tile isn't a target. It can hit 701 tiles, up to 15 tiles away.` |
| `siloStrike` at (40, 31) | `Striking there would start a war with player 25.` |

Date checked: game files on 2026-11-11. Running game on Windows on 2026-11-11.
