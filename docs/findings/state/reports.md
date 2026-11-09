# Reports tabs

Status: open. The resources of the Resources tab of Reports are confirmed in a running game with Gathering Storm against its screenshots. The City Status tab's growth rate, war weariness, and governor, which sit in `cities`, are confirmed on the same game.

The calls the state uses for the Resources and City Status tabs of Reports. The Yields tab is in [reports/yields.md](reports/yields.md). The top bar is in [state/player.md](player.md). See [design/core/mod/state.md](../../design/core/mod/state.md).

## Questions

None open for these tabs.

## What we know now

The Yields tab is in [reports/yields.md](reports/yields.md).

### Resources tab

`ReportScreen.lua` builds the tab in `GetData`, `AddResourceData`, `GetCityResourceData`, `AddMiscResourceData`, and `ViewResourcesPage`, and `ReportScreen_Expansion2.lua` replaces the city data and the misc data with the Gathering Storm stockpiles. Confirmed in files.

- **Sources.** Each resource has a list of sources and a total, which is their sum. A city's amount is `GetResourcesExtractedByCity(cityID, ResultFormat.SUMMARY)` with Gathering Storm, and the count of its purchased tiles for which `IsResourceExtractableAt` is true in the base game.

  A deal item with a duration, from `DealManager.GetPlayerDeals`, adds its amount for the other player's resource and takes it off for the player's own, with the turns left. A city-state the player is Suzerain of adds `GetExportedResourceAmount`.

  With Gathering Storm each resource adds the units' and power plants' demand per turn and the reserved amount as negatives, the city-states' `GetResourceImportPerTurn`, and a stockpile no source explains.

  A strategic resource's total is its accumulation per turn less the use, and `AddMiscResourceData` adds what is missing to it as Gameplay Bonuses, the state's `other`. An artifact is left out. Confirmed in files and on Windows on 2026-10-29.
- **Where they show.** A resource with no sources but a stockpile has no group, and shows only in the strip at the bottom, with its stockpile out of its cap.

  A resource with no sources and no stockpile isn't on the screen. The strategic strip shows `GetResourceAmount` over `GetResourceStockpileCap`, and the bonus and luxury strips the totals.

  `GetResourceAllocationCities(index)` gives the cities a resource goes to, each with `CityID` and `AllocationAmount`, and the screen shows their number as "4 Cities" with the amounts in its tooltip.

  Every luxury on the save but Marble was allocated to 4 cities. Confirmed in files and on Windows on 2026-10-29.
- **On the save.** 23 resources, in 7,040 bytes.

  Cattle was 5 from four cities, Crabs 5 with 1 from Gameplay Bonuses, and Stone 5 from three cities. The Turtles were 1 from a city, minus 1 exported to the player with ID 8 for 19 turns, plus 1 from Gameplay Bonuses.

  Whales were 1 for 4 cities. Aluminum, Coal, Oil, and Uranium were 105 from Gameplay Bonuses with a stockpile of 105 out of 105, as set with the tuner.

  Iron was 6 a turn with 105 out of 105, and Niter 2 with 32. Confirmed on Windows on 2026-10-29.

### City Status tab

`CreateCityStatusInstance` in `ReportScreen.lua`, which the Rise and Fall `ReportScreen_Expansion1.lua` replaces for Rise and Fall and Gathering Storm, builds each row from `GetCityData` in `CitySupport.lua`.

The Rise and Fall row drops the base game's Under Siege column and adds loyalty and the governor. Confirmed in files.

- **Growth rate status.** `GetHousingGrowthModifier()` of 0, or `IsOccupied()`, is Halted, a modifier of 0.5 or less is Slowed, `GetHappinessGrowthModifier()` above 0 is Accelerated, and anything else is Normal.

  The save's cities had modifiers of 1, 0.5, and 0.25, and no happiness modifier. Confirmed in files and on Windows on 2026-10-29.
- **War weariness and governor.** `GetAmenitiesLostFromWarWeariness()` is the amenities lost, which the tab shows as 0 or a negative number.

  `GetAssignedGovernor()`, which a city has only with Rise and Fall, gives the governor's type and `IsEstablished()`, which picks the icon's fill. Confirmed in files and on Windows on 2026-10-29.

## Method

1. For the Resources tab, send `SentientSystemsCore_StatePlayerResources.lua` as in [state/player.md](player.md#method), step 1, with `print(SentientSystems_EncodeJson(SentientSystems_GetResourcesState(Players[0])))`, and compare with the screen's groups and strips.

   To see a strategic resource at 0, set it with `Players[0]:GetResources():ChangeResourceAmount(index, -amount)` in `GameCore_Tuner`.
2. For the City Status tab, send `SentientSystemsCore_StateCities.lua` without its comments, then print each city's `growth.rate`, `amenities`, and `governor`, and compare with the tab.

## Results

A single-player game with Gathering Storm, in `SentientSystemsCore_UI`:

- **The Resources tab on the same save, through the bridge's reader.** `RESOURCES` parsed 23 resources. Totals, sources, the export deal, and the 4-city allocations matched the two screenshots, and the strips' stockpiles matched. With Uranium at 0 it was left out.
- **The City Status tab on the same save.** The 15 cities' growth rates matched the tab row for row, with 8 slowed and 7 normal, the amenities had and needed matched, war weariness was 0 for all, and the governors on Aduatuca, Samarobriva, and Cenabum matched its icons.

  Halted, accelerated, and war weariness above 0 weren't on the save, and are tested against the fake game only.

Date checked: game files and a running game on Windows on 2026-10-29, and game files on 2026-11-07.
