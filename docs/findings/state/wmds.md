# WMDs in the state

Status: confirmed. The `wmds` field of the player section and the `wmdLaunchers` section of `SentientSystems_GetState` are confirmed in a running game with Gathering Storm, with the files sent through the tuner. They match the top bar, the unit panel, and the silo banner.

The calls the nuclear stockpile and the launchers in the state use, as the top bar, the unit panel, and the missile silo banner show them. See [design/core/mod/state.md](../../design/core/mod/state.md).

## Questions

None open.

## What we know now

### Stockpile

`OnWMDUpdate` in `Base/Assets/UI/TopPanel.lua` and `DLC/Expansion2/UI/Replacements/TopPanel.lua` walks `GameInfo.WMDs()`.

It shows `Players[id]:GetWMDs():GetWeaponCount(row.Index)` for `WMD_NUCLEAR_DEVICE` and `WMD_THERMONUCLEAR_DEVICE`, and hides a count at 0. `Events.WMDCountChanged` refreshes it. Confirmed in files.

### Units

`GetUnitActionsTable` in `UnitPanel.lua` lists a unit's operations only while `GetMovesRemaining()` is above 0, so a unit with no moves left gets no strike button. `CanStartOperation` doesn't check moves, and returns `true` for that unit. Confirmed in files and on Windows on 2026-11-11.

With moves left, the panel asks `UnitManager.CanStartOperation(unit, UnitOperationTypes.WMD_STRIKE, nil, true)` once. It then asks once for each row of `GameInfo.WMDs()`, with the row's index in `UnitOperationTypes.PARAM_WMD_TYPE`.

Each device gets its own button, disabled when its check fails, with the failure reasons in the tooltip. Confirmed in files.

`UnitManager.GetOperationTargets` with the same parameters lists the tiles in range, 312 to 714 tiles for the bombers and the submarine in the save below. The state doesn't hold them.

### Missile silos

A silo isn't a unit. `CityBannerManager.lua` gives each improvement with `WeaponSlots` above 0 a mini banner, with its city from `Cities.GetPlotPurchaseCity(x, y)`. The banner shows only for the local player's silos. Confirmed in files.

`UpdateWMDBanner` enables a device's button when the player has one and `CityManager.GetCommandTargets(city, CityCommandTypes.WMD_STRIKE, parameters)` returns `CityCommandResults.PLOTS`.

The parameters hold the device in `PARAM_WMD_TYPE` and the silo's tile in `PARAM_X0` and `PARAM_Y0`. `OnICBMStrikeEnd` in `WorldInput.lua` fires the silo through the same city command. Confirmed in files.

A city's purchased plots, from `Map.GetCityPlots():GetPurchasedPlots(city)`, hold its silos, so the state finds them without a scan of the map.

## Method

1. In `SentientSystemsCore_UI`, for player 0, print `GetWeaponCount` for each row of `GameInfo.WMDs()`, `CanStartOperation` and the size of `GetOperationTargets` for each unit and device, and `GetCommandTargets` for each plot whose improvement has `WeaponSlots` above 0.
2. To read the section before the game loads the new files, send `SentientSystemsCore_StateWmdLaunchers.lua`, `SentientSystemsCore_StatePlayer.lua`, and `SentientSystemsCore_State.lua` to `SentientSystemsCore_UI`, each without its comments and `include` lines, then read the state from the bridge.
3. To spend a unit's moves, in `GameCore_Tuner`, send `UnitManager.FinishMoves(Players[0]:GetUnits():FindID(<unitID>))`.

## Results

A single-player game with Gathering Storm, player 0 with 3 nuclear and 4 thermonuclear devices, in `SentientSystemsCore_UI`:

| Call | Result |
| --- | --- |
| `GetWeaponCount` | 3 for `WMD_NUCLEAR_DEVICE`, 4 for `WMD_THERMONUCLEAR_DEVICE` |
| `CanStartOperation` for two jet bombers, a bomber, and a nuclear submarine | `true` for both devices on each |
| `GetCommandTargets` for the silo at (44, 30), through city 589832 | 462 tiles for the nuclear device and 701 for the thermonuclear one |
| The state | `wmds` with both counts, and both devices in `wmdLaunchers` with the four units and the silo, 195 bytes |
| `CanStartOperation` for a jet bomber on a carrier at (46, 33) after `FinishMoves` | `true`, with 0 moves and 1 attack left |
| The unit panel for that bomber | Only a button to cancel its activity, and no buttons once it was cancelled |
| The state, once it checks moves | The three other units and the silo, without that bomber |

Date checked: game files on 2026-11-11. Running game on Windows on 2026-11-11.
