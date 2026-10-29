# Game player overview

Status: open. The `player` section of `SentientSystems_GetState`, what the top bar shows about the player as a whole, is confirmed in a running game with Gathering Storm, with the file sent through the tuner. It matches the top bar. The income, expenses, unit upkeep, and gold deals of the Yields tab of Reports are confirmed on the same game, and the per-city rows are confirmed against the report's city table for the first city. Later tasks add the Resources, City Status, and Era Progress screens here.

The calls the player section of the state uses. See [in-game-lua.md](../design/core/in-game-lua.md).

## Questions

1. Does the top bar show the same numbers without Gathering Storm, and with a `CAPABILITY_` turned off?
2. Does the Yields tab's income by source give the same totals in a game with Gathering Storm turned off, and in another language?

## What we know now

### Top bar

`TopPanel.lua` draws the bar. The Rise and Fall file, `TopPanel_Expansion1.lua`, only changes the bar's background for a golden or dark age, and the Gathering Storm file, `TopPanel_Expansion2.lua`, adds the favor button and the strategic stockpiles. Confirmed in files.

- **Science and culture.** `RefreshYields` shows `GetTechs():GetScienceYield()` and `GetCulture():GetCultureYield()` per turn, in the number format `{1: number +#,###.#;-#,###.#}`, which rounds to the nearest tenth. They were 123.50390625 and 216.62109375, and the bar showed +123.5 and +216.6. Confirmed in files and on Windows on 2026-10-29.
- **Faith.** `GetReligion():GetFaithBalance()` in the format `#,###.#`, and `GetFaithYield()` per turn. They were 2357.01 and 109, and the bar showed 2,357 and +109. Confirmed in files and on Windows on 2026-10-29.
- **Gold.** The balance is `GetTreasury():GetGoldBalance()` rounded down, and the income per turn is `GetGoldYield()` less `GetTotalMaintenance()`, so the upkeep is already taken off. They were 9610.84 and 475.08 less 210, and the bar showed 9,610 and +265. Confirmed in files and on Windows on 2026-10-29.
- **Tourism.** `GetStats():GetTourism()` rounded to a tenth. The bar hides it at 0, as a turn 1 game showed, but the state always has it. It was 92 in a late save and 0 on turn 1. Confirmed in files and on Windows on 2026-10-29.
- **Trade routes.** `RefreshTrade` shows `GetTrade():GetNumOutgoingRoutes()` over `GetOutgoingRouteCapacity()`, and hides the button when the capacity is 0. They were 17 and 20. Confirmed in files and on Windows on 2026-10-29.
- **Favor.** With Gathering Storm only, the override of `RefreshYields` shows `GetFavor()` and `GetFavorPerTurn()`, which a player has only with that expansion. They were 335 and +3. Confirmed in files and on Windows on 2026-10-29.
- **Envoys.** The bar's envoy counter reads `GetInfluence()`, which the `envoys` section holds, so the player section leaves it out. Confirmed in files.
- **Capabilities.** The bar skips a yield when its `CAPABILITY_` is off, such as `CAPABILITY_SCIENCE`. The state doesn't check them, so a game that turns one off still gets the key. Confirmed in files.

### Yields tab

`ReportScreen.lua` and its Rise and Fall and Gathering Storm replacements draw the tab, with `CitySupport.lua` for the city data. The replacements change only the city status and the resources, so the yields come from the base file. Confirmed in files.

- **Totals.** The bar at the bottom shows `GetTreasury():GetGoldYield()`, which is the income before the upkeep, and `GetTotalMaintenance()` as the expenses. They were 475.08 and 210, and the screen showed +475, -210, and +265 net. The faith, science, and culture totals are the top bar's. Confirmed in files and on Windows on 2026-10-29.
- **Income by source.** The game gives no number for a source. `GetGoldYieldToolTip()`, `GetFaithYieldToolTip()`, `GetScienceYieldToolTip()`, and `GetCultureYieldToolTip()` return text, with lines such as `+33 from [ICON_Envoy] Envoys` and `+420 from Cities`, split by `[NEWLINE]`. The Treasury has no call for a source. The game's text keys for the lines, `LOC_PLAYER_YIELD_<YIELD>_FROM_<SOURCE>` in `InGameText.xml`, return an empty text from `Locale.Lookup`, with a number or without, so the labels can't be read in the player's language. The state matches the English labels, and anything else, such as another language, lands in `other`. Gold has Cities, Deals, Beliefs, Envoys, city-states you are Suzerain of, interest on treasury, National Parks, and Other. Faith adds peaceful religion founders, Religious Alliances, and excess Great Person points. The tooltips also list each city, which the per-city rows will use. On the save, gold was 420 from cities, 22 from deals, and 33 from envoys, the Merchant Confederation card's +1 gold for each envoy, which the game doesn't name. Faith was 101 from cities and 8 from excess Great Person points. Confirmed in files and on Windows on 2026-10-29.
- **Per-city rows.** The city table lists, for each city, its districts with their yields, an adjacency row, and the buildings in each, then the wonders, the trade routes, the worked tiles, the amenities, and the population. `district:GetYield` and `GetAdjacencyYield` by yield index give the district rows, `city:GetBuildingYield(buildingIndex, "YIELD_GOLD")` the building rows, and `GameInfo.GreatWork_YieldChanges()` the great works in a building, found through `GetNumGreatWorkSlots`, `GetGreatWorkInSlot`, and `GetGreatWorkTypeFromIndex`. The wonders sit in `DISTRICT_WONDER` districts, which the table leaves out, and follow the districts. `GetTrade():GetOutgoingRoutes()` has `OriginYields`, with the destination city's player and ID. The worked tiles are the sum of `plot:GetYield` over the purchased plots with `GetCitizens():IsPlotWorked`, and the city's tourism is the sum of `GetTourismAt`. A city that isn't content, `GetHappiness() ~= 4`, gets an amenities row of a tenth of the worked tiles' yields but food, times `Round(1 + GetHappinessNonFoodYieldModifier() / 100, 2)`, and the population gives `GameInfo.GlobalParameters.CULTURE_PERCENTAGE_YIELD_PER_POP` percent of itself as culture, 30 here. The rows of a city don't add up to its yield, as the table's don't: the first city's culture was 16.4 in rows and 20.3 in its header. The state leaves out rows with no yield and no upkeep. Aduatuca's rows matched the table's, from the Monument to the Population, and the 15 cities held 235 rows in 23,646 bytes with the rest of `income`. Their upkeep added up to 117 and their tourism to 92, which is the top bar's. Confirmed on Windows on 2026-10-29.
- **Upkeep of districts and buildings.** The report's Building Expenses table lists only districts, because the Gathering Storm `CitySupport.lua` fills each building's maintenance from `GetBuildingMaintenance`, which returns 0 for every building. The cost is in the building's row, `GameInfo.Buildings[].Maintenance`, and a district's in `GameInfo.Districts[].Maintenance`. The top bar's tooltip adds the districts that are built and not pillaged and the buildings that aren't, which came to 36 and 81, so 117 from cities. `GetBuildingMaintenance` on the Treasury gave 84, which counts the two pillaged buildings. Confirmed on Windows on 2026-10-29.
- **Units.** `UnitManager.GetUnitMaintenance`, `GetUnitCorpsMaintenance`, and `GetUnitArmyMaintenance` by the unit's hash, less `GetMaintDiscountPerUnit()`, which was 1. They came to 88 for 31 units in 7 groups, as the Unit Expenses table showed. The report's `MilitaryFormationTypes.CORPS_FORMATION` and the choices' `CORPS_MILITARY_FORMATION` are both 1. Confirmed in files and on Windows on 2026-10-29.
- **Deals.** `DealManager.GetPlayerDeals(player, other)`, then `FindItemsByType(DealItemTypes.GOLD, DealItemSubTypes.NONE, owner)` for the player's own gold and for the other player's, each item with `GetAmount`, `GetDuration`, and `GetEnactedTurn`. The turns left are the duration less the turns since it was enacted, and an item with no duration is skipped. They were +3, -5, +5, and +14, which the Diplomatic Deals table showed with the same turns, and +17 together. The expenses were 117 from cities, 88 from units, and 5 from deals, which makes the 210. Confirmed on Windows on 2026-10-29.

## Method

1. To read the player section before the `.modinfo` loads `SentientSystemsCore_StatePlayer.lua`, send the file with its comment lines removed, then `print(SentientSystems_EncodeJson(SentientSystems_GetPlayerState(Players[0])))`, as in [game-choices.md](game-choices.md#method), step 6.
2. Compare each value with the top bar.
3. For the Yields tab, send `SentientSystemsCore_StatePlayerIncome.lua` the same way, with `print(SentientSystems_EncodeJson(SentientSystems_GetIncomeState(Players[0])))`, and compare with the screen's bottom bar and tables, and with the gold tooltip of the top bar.

## Results

A single-player game with Gathering Storm, in `SentientSystemsCore_UI`:

| Check | Result |
| --- | --- |
| The player section against the top bar | Science 123.5, culture 216.6, faith 2,357 and 109, gold 9,610 and 265.1, tourism 92, trade routes 17 of 20, favor 335 and 3. All matched the bar 
| The player section on turn 1 of a new game | Science 0, culture 0, faith 0 and 0, gold 5 and 0, favor 0 and 0, tourism 0, and no trade routes. The bar showed the same, with the favor button showing 0 and 0, no tourism, and the envoy counter at 0 |
| The per-city rows through the bridge's reader | `INCOME` parsed. Aduatuca's 21 rows matched the report's table, with a Shipyard upkeep of 1 and a Factory upkeep of 2, and its upkeep of 9 and tourism of 18 as the table and the sum of its Stable, Armory, and the rest gave |
| The Yields tab's totals and tables on a save with 15 cities | Gold 475.1 with 420 from cities, 22 from deals, and 33 from envoys, faith 109 with 101 and 8, science 123.5 and culture 216.6 from cities. Expenses 210: 117 from cities, 88 from units, and 5 from deals. 7 unit groups and 4 deals, as the screen's tables had them. The state's totals matched the bar and the gold tooltip |

Date checked: game files and a running game on Windows on 2026-10-29.
