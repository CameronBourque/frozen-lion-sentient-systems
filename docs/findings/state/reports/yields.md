# Yields tab

Status: open. The income, expenses, unit upkeep, and gold deals of the Yields tab of Reports are confirmed in a running game with Gathering Storm, and the per-city rows are confirmed against the report's city table for the first city.

The calls the state uses for the Yields tab of Reports. The top bar is in [state/player.md](../player.md). See [design/core/mod/state.md](../../../design/core/mod/state.md) and the [Reports index](README.md).

## Questions

1. Does the Yields tab's income by source give the same totals in a game with Gathering Storm turned off, and in another language?

## What we know now

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

## Method

1. Send `SentientSystemsCore_StatePlayerIncome.lua` as in [state/player.md](../player.md#method), step 1, with `print(SentientSystems_EncodeJson(SentientSystems_GetIncomeState(Players[0])))`. Compare with the screen's bottom bar and tables, and with the gold tooltip of the top bar.

## Results

A single-player game with Gathering Storm, in `SentientSystemsCore_UI`:

- **The Yields tab's totals and tables on a save with 15 cities.** Gold 475.1 with 420 from cities, 22 from deals, and 33 from envoys, faith 109 with 101 and 8, science 123.5 and culture 216.6 from cities.

  Expenses 210: 117 from cities, 88 from units, and 5 from deals. The state's totals matched the bar and the gold tooltip.
- **The per-city rows through the bridge's reader.** `INCOME` parsed. Aduatuca's 21 rows matched the report's table, with a Shipyard upkeep of 1 and a Factory upkeep of 2, and its upkeep of 9 and tourism of 18 as the table and the sum of its Stable, Armory, and the rest gave.

Date checked: game files and a running game on Windows on 2026-10-29, and game files on 2026-11-07.
