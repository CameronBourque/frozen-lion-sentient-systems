# Reports tabs

Status: open. The income, expenses, unit upkeep, and gold deals of the Yields tab of Reports are confirmed in a running game with Gathering Storm, and the per-city rows are confirmed against the report's city table for the first city.

The resources of the Resources tab are confirmed on the same game against its screenshots. The City Status tab's growth rate, war weariness, and governor, which sit in `cities`, are confirmed on the same game.

The calls the state uses for the Yields, Resources, and City Status tabs of Reports. The top bar is in [state/player.md](player.md). See [design/core/mod/state.md](../../design/core/mod/state.md).

## Questions

1. Does the Yields tab's income by source give the same totals in a game with Gathering Storm turned off, and in another language?

## What we know now

### Yields tab

`ReportScreen.lua` and its Rise and Fall and Gathering Storm replacements draw the tab, with `CitySupport.lua` for the city data. The replacements change only the city status and the resources, so the yields come from the base file. Confirmed in files.

The tab writes its numbers with `toPlusMinusString` in `Civ6Common.lua`, which rounds to the nearest tenth. Confirmed in files on 2026-11-07.

- **Totals.** The bar at the bottom shows `GetTreasury():GetGoldYield()`, which is the income before the upkeep, and `GetTotalMaintenance()` as the expenses.

  They were 475.08 and 210, and the screen showed +475, -210, and +265 net. The faith, science, and culture totals are the top bar's. Confirmed in files and on Windows on 2026-10-29.
- **Income by source.** The game gives no number for a source. `GetGoldYieldToolTip()`, `GetFaithYieldToolTip()`, `GetScienceYieldToolTip()`, and `GetCultureYieldToolTip()` return text, with lines such as `+33 from [ICON_Envoy] Envoys` and `+420 from Cities`, split by `[NEWLINE]`.

  The Treasury has no call for a source. The game's text keys for the lines, `LOC_PLAYER_YIELD_<YIELD>_FROM_<SOURCE>` in `InGameText.xml`, return an empty text from `Locale.Lookup`, with a number or without, so the labels can't be read in the player's language.

  The state matches the English labels, and anything else, such as another language, lands in `other`. Gold has Cities, Deals, Beliefs, Envoys, city-states you are Suzerain of, interest on treasury, National Parks, and Other.

  Faith adds peaceful religion founders, Religious Alliances, and excess Great Person points. The tooltips also list each city, which the per-city rows will use.

  On the save, gold was 420 from cities, 22 from deals, and 33 from envoys, the Merchant Confederation card's +1 gold for each envoy, which the game doesn't name. Faith was 101 from cities and 8 from excess Great Person points. Confirmed in files and on Windows on 2026-10-29.
- **Per-city rows.** The city table lists, for each city, its districts with their yields, an adjacency row, and the buildings in each, then the wonders, the trade routes, the worked tiles, the amenities, and the population.

  `district:GetYield` and `GetAdjacencyYield` by yield index give the district rows, and `city:GetBuildingYield(buildingIndex, "YIELD_GOLD")` the building rows.

  `GameInfo.GreatWork_YieldChanges()` gives the great works in a building, found through `GetNumGreatWorkSlots`, `GetGreatWorkInSlot`, and `GetGreatWorkTypeFromIndex`.

  The wonders sit in `DISTRICT_WONDER` districts, which the table leaves out, and follow the districts. `GetTrade():GetOutgoingRoutes()` has `OriginYields`, with the destination city's player and ID.

  The worked tiles are the sum of `plot:GetYield` over the purchased plots with `GetCitizens():IsPlotWorked`, and the city's tourism is the sum of `GetTourismAt`.

  A city that isn't content, `GetHappiness() ~= 4`, gets an amenities row of a tenth of the worked tiles' yields but food, times `Round(1 + GetHappinessNonFoodYieldModifier() / 100, 2)`.

  The population gives `GameInfo.GlobalParameters.CULTURE_PERCENTAGE_YIELD_PER_POP` percent of itself as culture, 30 here.

  The rows of a city don't add up to its yield, as the table's don't: the first city's culture was 16.4 in rows and 20.3 in its header. The state leaves out rows with no yield and no upkeep.

  Aduatuca's rows matched the table's, from the Monument to the Population, and the 15 cities held 235 rows in 23,646 bytes with the rest of `income`. Their upkeep added up to 117 and their tourism to 92, which is the top bar's. Confirmed on Windows on 2026-10-29.
- **Upkeep of districts and buildings.** The report's Building Expenses table lists only districts, because the Gathering Storm `CitySupport.lua` fills each building's maintenance from `GetBuildingMaintenance`, which returns 0 for every building.

  The cost is in the building's row, `GameInfo.Buildings[].Maintenance`, and a district's in `GameInfo.Districts[].Maintenance`.

  The top bar's tooltip adds the districts that are built and not pillaged and the buildings that aren't, which came to 36 and 81, so 117 from cities. `GetBuildingMaintenance` on the Treasury gave 84, which counts the two pillaged buildings. Confirmed on Windows on 2026-10-29.
- **Units.** `UnitManager.GetUnitMaintenance`, `GetUnitCorpsMaintenance`, and `GetUnitArmyMaintenance` by the unit's hash, less `GetMaintDiscountPerUnit()`, which was 1.

  They came to 88 for 31 units in 7 groups, as the Unit Expenses table showed. The report's `MilitaryFormationTypes.CORPS_FORMATION` and the choices' `CORPS_MILITARY_FORMATION` are both 1. Confirmed in files and on Windows on 2026-10-29.
- **Deals.** `DealManager.GetPlayerDeals(player, other)`, then `FindItemsByType(DealItemTypes.GOLD, DealItemSubTypes.NONE, owner)` for the player's own gold and for the other player's, each item with `GetAmount`, `GetDuration`, and `GetEnactedTurn`.

  The turns left are the duration less the turns since it was enacted, and an item with no duration is skipped. They were +3, -5, +5, and +14, which the Diplomatic Deals table showed with the same turns, and +17 together.

  The expenses were 117 from cities, 88 from units, and 5 from deals, which makes the 210. Confirmed on Windows on 2026-10-29.

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

1. For the Yields tab, send `SentientSystemsCore_StatePlayerIncome.lua` as in [state/player.md](player.md#method), step 1, with `print(SentientSystems_EncodeJson(SentientSystems_GetIncomeState(Players[0])))`. Compare with the screen's bottom bar and tables, and with the gold tooltip of the top bar.
2. For the Resources tab, send `SentientSystemsCore_StatePlayerResources.lua` as in [state/player.md](player.md#method), step 1, with `print(SentientSystems_EncodeJson(SentientSystems_GetResourcesState(Players[0])))`, and compare with the screen's groups and strips.

   To see a strategic resource at 0, set it with `Players[0]:GetResources():ChangeResourceAmount(index, -amount)` in `GameCore_Tuner`.
3. For the City Status tab, send `SentientSystemsCore_StateCities.lua` without its comments, then print each city's `growth.rate`, `amenities`, and `governor`, and compare with the tab.

## Results

A single-player game with Gathering Storm, in `SentientSystemsCore_UI`:

- **The Yields tab's totals and tables on a save with 15 cities.** Gold 475.1 with 420 from cities, 22 from deals, and 33 from envoys, faith 109 with 101 and 8, science 123.5 and culture 216.6 from cities.

  Expenses 210: 117 from cities, 88 from units, and 5 from deals. The state's totals matched the bar and the gold tooltip.
- **The per-city rows through the bridge's reader.** `INCOME` parsed. Aduatuca's 21 rows matched the report's table, with a Shipyard upkeep of 1 and a Factory upkeep of 2, and its upkeep of 9 and tourism of 18 as the table and the sum of its Stable, Armory, and the rest gave.
- **The Resources tab on the same save, through the bridge's reader.** `RESOURCES` parsed 23 resources. Totals, sources, the export deal, and the 4-city allocations matched the two screenshots, and the strips' stockpiles matched. With Uranium at 0 it was left out.
- **The City Status tab on the same save.** The 15 cities' growth rates matched the tab row for row, with 8 slowed and 7 normal, the amenities had and needed matched, war weariness was 0 for all, and the governors on Aduatuca, Samarobriva, and Cenabum matched its icons.

  Halted, accelerated, and war weariness above 0 weren't on the save, and are tested against the fake game only.

Date checked: game files and a running game on Windows on 2026-10-29, and game files on 2026-11-07.
