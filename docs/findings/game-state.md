# Game state

Status: open. `SentientSystems_GetState` with cities, units, revealed tiles, revealed rival cities, and visible rival units is confirmed in a running game.

The calls the state serializer uses to build one player's view of the game, with the Lua state each one runs in. The view must hold what that player can know and nothing more. What a player can know about each tile and the rivals on it is in [tile-visibility.md](tile-visibility.md). See [in-game-lua.md](../design/core/in-game-lua.md).

## Questions

None open.

## What we know now

### Cities

`SentientSystems_GetState(playerID)` in `SentientSystemsCore_UI` lists the player's cities from `Players[playerID]:GetCities():Members()`. Each city has `GetID()`, `GetName()`, `GetX()`, `GetY()`, and `GetPopulation()`. `GetName()` returns a text key, such as `LOC_CITY_NAME_ROME`, and `Locale.Lookup` gives the name in the game's language, such as `Rome`. Confirmed on Windows on 2026-10-24.

- **Production.** `city:GetBuildQueue():GetCurrentProductionTypeHash()` returns the hash of what the city is producing, or 0 when it produces nothing. `GameInfo.Types[hash]` gives the row, with `Type`, such as `UNIT_SLINGER`, and `Kind`, such as `KIND_UNIT`. `GetTurnsLeft` takes the hash or the type name, and both return the same turns. `GetCurrentProductionInfoOfCity` in `Base/Assets/UI/CitySupport.lua`, lines 40 to 49, reads the same hash, and `GetProductionInfoOfCity` treats 0 as nothing, at lines 186 to 200. Confirmed in files and on Windows on 2026-10-24.
- **A hash of 0 isn't a production.** `GameInfo` tables read a number as a row index, so with a hash of 0, `GameInfo.Buildings[0]` returned `BUILDING_MONUMENT` and `GameInfo.Types[0]` returned `TRAIT_AGENDA_ALLY_OF_ENKIDU`, the first row of each. `GetTurnsLeft(0)` returned 4. Check for 0 before any lookup. Confirmed on Windows on 2026-10-24.
- **Growth.** `city:GetGrowth()` has `GetTurnsUntilGrowth()`, `GetTurnsUntilStarvation()`, and `GetFoodSurplus()`. Each count is -1 when it doesn't apply. `GetCityData` in `Base/Assets/UI/CitySupport.lua`, lines 474 to 486, shows the turns until growth when that count isn't -1, the turns until starvation as a loss otherwise, and 0 when both are -1. Confirmed in files and on Windows on 2026-10-24.
- **Amenities and housing.** `city:GetGrowth()` also has `GetAmenities()`, `GetAmenitiesNeeded()`, `GetHappiness()`, and `GetHousing()`. The city panel shows amenities as have minus need, in `GetCityData` in `CitySupport.lua`, line 526, and housing from line 562. `GetHappiness()` returns an index in `GameInfo.Happinesses`, from 0, `HAPPINESS_REVOLT`, to 6, `HAPPINESS_ECSTATIC`, with 4 for `HAPPINESS_CONTENT`. Confirmed in files and on Windows on 2026-10-24.
- **Loyalty.** With the Rise and Fall expansion or Gathering Storm, `city:GetCulturalIdentity()` has `GetLoyalty()`, `GetMaxLoyalty()`, and `GetLoyaltyPerTurn()`. The city panel rounds loyalty to the nearest tenth with `Round(currentLoyalty, 1)`, in `DLC/Expansion1/UI/Additions/CityPanelCulture.lua`, lines 86 to 98. The base game has no `GetCulturalIdentity`. Confirmed in files, and the calls on Windows on 2026-10-24.
- **Districts and buildings.** `city:GetDistricts():Members()` lists the city's districts. Each has `GetType()`, an index in `GameInfo.Districts`, `GetX()`, `GetY()`, `IsComplete()`, and `IsPillaged()`. `city:GetBuildings():GetBuildingsAtLocation(plotIndex)` lists the building indexes on a district's tile, and `HasBuilding(index)` and `IsPillaged(index)` tell whether each is built and pillaged. `GetCityData` in `CitySupport.lua`, lines 600 to 760, reads the same calls, and puts wonders in `DISTRICT_WONDER`. Confirmed in files and on Windows on 2026-10-24.
- **Yields.** `city:GetYield(YieldTypes.FOOD)` and the same for `PRODUCTION`, `GOLD`, `SCIENCE`, `CULTURE`, and `FAITH` return each yield per turn, with all its decimals, such as 3.8984375 for culture. The city panel rounds each one down to one decimal place with `math.floor(x * 10) / 10`, in `CitySupport.lua`, lines 316 to 332, so it shows 3.8. Confirmed in files and on Windows on 2026-10-24.

### Units

`SentientSystems_GetState(playerID)` lists the player's units from `Players[playerID]:GetUnits():Members()`. Each unit has `GetID()`, `GetType()`, an index in `GameInfo.Units`, `GetX()`, `GetY()`, `GetMovesRemaining()`, `GetMaxMoves()`, `GetDamage()`, and `GetMaxDamage()`. The unit panel reads the same calls in `Base/Assets/UI/Panels/UnitPanel.lua`, lines 2237 to 2245, and shows health as `MaxDamage - Damage` out of `MaxDamage`, at line 1055. `UnitFlagManager.lua` makes no flag for a unit whose `IsDead()` or `IsDelayedDeath()` is `true`. Confirmed in files and on Windows on 2026-10-24.

### Promotions

- `unit:GetExperience()` has `GetExperiencePoints()`, `GetExperienceForNextLevel()`, `GetLevel()`, and `GetPromotions()`. `GetPromotions()` returns indexes in `GameInfo.UnitPromotions`, whose rows have `UnitPromotionType`, such as `PROMOTION_RANGER`. The unit panel reads the experience in `Base/Assets/UI/Panels/UnitPanel.lua`, lines 2262 and 2263, and `UnitPromotionPopup.lua` reads the promotions at line 85. Confirmed in files and on Windows on 2026-10-24.
- `UnitManager.CanStartCommand(unit, UnitCommandTypes.PROMOTE, true, true)` returns `true` and a results table when the unit can promote. `results[UnitCommandResults.PROMOTIONS]` lists the indexes of the promotions it can pick. The unit panel builds its promotion list this way, in `UnitPanel.lua`, lines 435 to 446. It returns `false` and no results, with no failure reasons, for a unit without enough experience, and for one with enough experience but no moves left. `unit:GetExperience():CanPromote()` in `GameCore_Tuner` returns `true` once the experience is enough, with or without moves. Confirmed in files and on Windows on 2026-10-24.

### Tiles

`SentientSystems_GetState(playerID)` lists each plot, from 0 to `Map.GetPlotCount() - 1`, for which `PlayersVisibility[playerID]:IsRevealed(index)` is `true`. `Map.GetPlotByIndex(index)` gives the plot, whose `GetTerrainType()` and `GetFeatureType()` are indexes in `GameInfo.Terrains` and `GameInfo.Features`. `GetFeatureType()` returns -1 for a plot with no feature, and `GameInfo.Features[-1]` is `nil`. `GetResourceType()`, `GetDistrictType()`, `GetImprovementType()`, and `GetRouteType()` work the same way with `GameInfo.Resources`, `GameInfo.Districts`, `GameInfo.Improvements`, and `GameInfo.Routes`, and each table returns `nil` for -1. `GameInfo.Routes[0]` is `ROUTE_ANCIENT_ROAD`. `GetOwner()` returns a player ID, or -1 for no owner. `IsImprovementPillaged()` and `IsRoutePillaged()` tell whether the improvement or road is pillaged. The tooltip shows the same values, in `PlotToolTip.lua`, lines 197 to 480 and 633 to 685. Which of these a player can know is in [tile-visibility.md](tile-visibility.md). Confirmed on Windows on 2026-10-24.

### Rival cities

`PlayerManager.GetAlive()` lists every living player, and each player's cities come from `GetCities():Members()`, as for the player's own. City IDs repeat across players: Rome and Râ-Kedet both had ID 65536. `city:IsCapital()` tells whether a city is its owner's capital. The city banner reads a city's defense from its city center, for the player's own cities and for rivals', `Players[owner]:GetDistricts():FindID(city:GetDistrictID())`. That district's `GetDefenseStrength()` is the banner's defense number, rounded with `math.floor(x + 0.5)`. `GetDamage` and `GetMaxDamage` with `DefenseTypes.DISTRICT_GARRISON` give the garrison's health, and with `DefenseTypes.DISTRICT_OUTER` the walls' health, whose most is 0 for a city with no walls. See `CityBanner:UpdateStats` in `DLC/Expansion1/UI/CityBanners/CityBannerManager.lua`, lines 1209 to 1260. Confirmed in files and on Windows on 2026-10-24.

### Rival units

Each living player's units come from `GetUnits():Members()`, with the same calls as the player's own. Unit IDs repeat across players: player 0's scout and player 1's builder both had ID 196608, and both warriors had ID 131073. A rival unit is visible to the player when `PlayersVisibility[playerID]:IsVisible(x, y)` and `IsUnitVisible(unit)` are both `true`. See [tile-visibility.md](tile-visibility.md#rival-cities-and-units). Confirmed on Windows on 2026-10-24.

## Method

1. In `SentientSystemsCore_UI`, call each city, unit, and tile call for the local player, and compare the values with the city panel, the unit panel, and the tooltip.
2. Read `SentientSystems_GetState(Game.GetLocalPlayer())` through `SentientSystems_Stash` and `SentientSystems_PrintPiece`, parse it with `JSON.parse`, and compare it with the calls.
3. To change a file in `Scripts/` without a load, send `SentientSystems_Include("<file name>")` first. See [lua-contexts.md](lua-contexts.md#the-core-mods-states).

## Results

A single-player game on a 44 by 26 map, in `SentientSystemsCore_UI`.

`SentientSystems_GetState(0)`, on turn 14 of the same game, read through `SentientSystems_Stash` and `SentientSystems_PrintPiece`:

| Check | Result |
| --- | --- |
| The state | `{"cities":[{"id":65536,"name":"Rome","population":3,"x":17,"y":14}]}`, 68 bytes in 1 piece |
| Time for the stash and the piece | 66 ms |
| The same city from the city calls | ID 65536, `LOC_CITY_NAME_ROME`, `Rome`, at (17,14), population 3 |
| `SentientSystems_GetState(99)` | Raised `no player 99` |

Rome's production and yields on turn 14, from the calls, matched the city panel. The panel showed **Slinger** with 2 turns until completed, and +9 food, +6 production, +8 gold, +3.5 science, +3.8 culture, and 0 faith:

| Call | Result |
| --- | --- |
| `GetCurrentProductionTypeHash()` with nothing in production | 0 |
| `GetCurrentProductionTypeHash()` with a slinger in production | 1558890441 |
| `GameInfo.Types[1558890441]` | `UNIT_SLINGER`, `KIND_UNIT` |
| `GetTurnsLeft("UNIT_SLINGER")` and `GetTurnsLeft(1558890441)` | 2 and 2 |
| `GetYield` for food, production, gold, science, culture, and faith | 9, 6, 8, 3.5, 3.8984375, and 0 |
| `GetGrowth():GetTurnsUntilGrowth()` and `GetFoodSurplus()` | 2 and 3. The panel showed 2 turns until growth |
| `GetAmenities()`, `GetAmenitiesNeeded()`, and `GetHappiness()` | 2, 2, and 4, `HAPPINESS_CONTENT`. The panel showed 0 amenities |
| `GetHousing()` with population 3 | 6. The panel showed housing 3/6 |
| `GetCulturalIdentity()`: `GetLoyalty()`, `GetMaxLoyalty()`, and `GetLoyaltyPerTurn()` | 100, 100, and 21. The panel showed 100 loyalty |
| `GetDistricts():Members()` | One district, ID 65536, `DISTRICT_CITY_CENTER` at (17,14), complete and not pillaged |
| `GetBuildingsAtLocation` on the city center | Indexes 0, `BUILDING_MONUMENT`, and 1, `BUILDING_PALACE`, both built and not pillaged |
| `GetUnits():Members()` | `UNIT_SCOUT`, ID 196608, at (24,15), and `UNIT_WARRIOR`, ID 131073, at (7,13). Each had 0 moves left, of 3 and 2, and 0 damage of 100. Neither was dead or about to die |
| `GetExperience()` for the scout and the warrior | Each had 0 of 15 experience points, level 1, and no promotions |
| `CanStartCommand` for `PROMOTE` for each unit | `false` and no results |
| Tiles in the state, against a loop over every plot | 161 revealed, 61 visible, and 66 with a feature in both. Rome's tile at (17,14) was `TERRAIN_PLAINS` with no feature, and visible |
| The whole state, with one city, two units, and 161 tiles | 12,380 bytes in one piece |
| Owners, districts, improvements, and roads in the state, against a loop over every revealed plot | 17 owned tiles in both, 10 of player 0 and 7 of player 1. 2 districts and 2 roads, the city centers of Rome at (17,14) and Râ-Kedet at (30,18), each with `ROUTE_ANCIENT_ROAD`. No improvements, and nothing pillaged. The state grew to 13,589 bytes |
| Rival cities in the state, against the calls for every city | Râ-Kedet, player 1's capital, at (30,18) on a fogged tile: population 2, defense 13, garrison 200 of 200, and no walls, as its banner showed. Rome, the player's own, was left out |
| Rival units in the state, against the calls for every unit | Player 1's warrior at (25,14), on a visible tile with `IsUnitVisible` `true`, at full health. Player 1's builder at (29,17), on a fogged tile with `IsUnitVisible` `false`, was left out |
| Resources in the state, against `IsResourceVisible` on every revealed plot | 32 visible resources in both, tile for tile. The state left out the 6 hidden ones: aluminum at (8,7) and (19,15), oil at (10,7), niter at (10,9), iron at (12,9), and coal at (25,16). The state grew to 13,293 bytes |
| The scout, after `GetExperience():ChangeExperience(15)` in `GameCore_Tuner` | 15 of 15 experience, and `CanPromote()` returned `true`. With 0 moves left, `CanStartCommand` for `PROMOTE` still returned `false` and no results |
| The scout, after `UnitManager.RestoreMovement` in `GameCore_Tuner` gave it 3 moves | `CanStartCommand` for `PROMOTE` returned `true`, with promotion indexes 0, `PROMOTION_RANGER`, and 1, `PROMOTION_ALPINE`. The state listed both in `availablePromotions` |

Date checked: game files on 2026-10-24. Running game on Windows on 2026-10-24.
