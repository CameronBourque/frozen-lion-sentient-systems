# Placement tiles

Status: confirmed. The tiles from `SentientSystems_GetPlacement` are confirmed in a running game. The tiles to buy that the panel counts are confirmed in files only.

The calls the placement call uses to find where a city can place a district or a wonder, as the placement view shows the tiles. The other choices are in the [choices index](README.md). See [design/core/mod/choices.md](../../design/core/mod/choices.md#placement).

## Questions

None open.

## What we know now

### Placement tiles

`Base/Assets/UI/AdjacencyBonusSupport.lua` finds the tiles where a district or a wonder can go. The expansions don't replace it. Confirmed in files.

- **Tiles the city owns.** `CityManager.GetOperationTargets(city, CityOperationTypes.BUILD, params)` returns plot indexes in `results[CityOperationResults.PLOTS]`.

  For a district, `params[CityOperationTypes.PARAM_DISTRICT_TYPE]` is set to its hash, and for a wonder, `params[CityOperationTypes.PARAM_BUILDING_TYPE]`.

  Confirmed in files and on Windows on 2026-10-26.
- **Tiles to buy.** `CityManager.GetCommandTargets(city, CityCommandTypes.PURCHASE, params)` returns the plot indexes the city could buy in `results[CityCommandResults.PLOTS]`.

  `params[CityCommandTypes.PARAM_PLOT_PURCHASE]` is set to `UI.GetInterfaceModeParameter(CityCommandTypes.PARAM_PLOT_PURCHASE)`.

  `plot:CanHaveDistrict(districtIndex, owner, cityID)` and `plot:CanHaveWonder(buildingIndex, owner, cityID)` check each one. Both work in `SentientSystemsCore_UI`. Rome had 17 tiles to buy. Confirmed in files and on Windows on 2026-10-26.
- **Tiles to buy that the panel counts.** For a district, `IsShownIfPlotPurchaseable`, lines 155 to 169, keeps a tile to buy only when the district gets an adjacency bonus on it, or when the district has no adjacency bonuses.

  For a wonder, it keeps every tile that `CanHaveWonder` allows. Confirmed in files.
- **Adjacency.** `plot:GetAdjacencyYield(playerID, cityID, districtIndex, yieldIndex)` returns a district's bonus on a tile for one yield. `GetAdjacentYieldBonusString`, lines 177 to 247, reads it for each yield. Confirmed in files and on Windows on 2026-10-26.
- **Wonders with no tile the city owns.** When `CanProduce` refuses a wonder with `results[CityOperationResults.NO_SUITABLE_LOCATION]` set to `true`, the panel doesn't grey it out if it has a tile to buy, in `GetData`, lines 2041 to 2047.

  The Pyramids, the Great Bath, and Stonehenge each had no tile in Rome's territory and one tile to buy, and Rome's panel showed the Pyramids and the Great Bath in the same style as the buildings. Confirmed in files and on Windows on 2026-10-26.

## Method

1. To unlock districts and wonders, send `SetTech` as in [choices/production.md](production.md#method), step 2.
2. Read `SentientSystems_GetPlacement` for a city and a district or a wonder through `readPlacement`.

## Results

A single-player game with Gathering Storm, on turn 14, with one city, Rome, at 3 population, in `SentientSystemsCore_UI`:

- **`SentientSystems_GetPlacement` through `readPlacement`, for Rome.** The campus had the same 3 tiles and 8 tiles to buy, with the same bonuses, 335 bytes.

  The Pyramids had no tile and 1 tile to buy, (17,17), 46 bytes. The granary raised `BUILDING_GRANARY isn't a district or a wonder`, and city 7 raised an error for the missing city.

Date checked: game files on 2026-10-26. Running game on Windows on 2026-10-26.
