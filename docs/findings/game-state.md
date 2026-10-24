# Game state

Status: open. What a player knows about each tile, the calls that give the core mod that knowledge, and what FireTuner's map reveal changes are confirmed from the game's files and in a running game. `SentientSystems_GetState` with cities is confirmed in a running game. The state calls for units are not checked yet.

The calls the state serializer uses to build one player's view of the game, with the Lua state each one runs in. The view must hold what that player can know and nothing more. See [in-game-lua.md](../design/core/in-game-lua.md).

## Questions

1. Does `PlayerManager.SetLocalObserverTo(PlayerTypes.OBSERVER)` show the whole map without changing any player's `PlayersVisibility`? Do the action API's requests still work while it's on? **Set Observer To OBSERVER** on FireTuner's **Map** panel calls it, in `<game>\Debug\Map.ltp`. Test in phase 4.

## What we know now

### Cities

`SentientSystems_GetState(playerID)` in `SentientSystemsCore_UI` lists the player's cities from `Players[playerID]:GetCities():Members()`. Each city has `GetID()`, `GetName()`, `GetX()`, `GetY()`, and `GetPopulation()`. `GetName()` returns a text key, such as `LOC_CITY_NAME_ROME`, and `Locale.Lookup` gives the name in the game's language, such as `Rome`. Confirmed on Windows on 2026-10-24.

- **Production.** `city:GetBuildQueue():GetCurrentProductionTypeHash()` returns the hash of what the city is producing, or 0 when it produces nothing. `GameInfo.Types[hash]` gives the row, with `Type`, such as `UNIT_SLINGER`, and `Kind`, such as `KIND_UNIT`. `GetTurnsLeft` takes the hash or the type name, and both return the same turns. `GetCurrentProductionInfoOfCity` in `Base/Assets/UI/CitySupport.lua`, lines 40 to 49, reads the same hash, and `GetProductionInfoOfCity` treats 0 as nothing, at lines 186 to 200. Confirmed in files and on Windows on 2026-10-24.
- **A hash of 0 isn't a production.** `GameInfo` tables read a number as a row index, so with a hash of 0, `GameInfo.Buildings[0]` returned `BUILDING_MONUMENT` and `GameInfo.Types[0]` returned `TRAIT_AGENDA_ALLY_OF_ENKIDU`, the first row of each. `GetTurnsLeft(0)` returned 4. Check for 0 before any lookup. Confirmed on Windows on 2026-10-24.
- **Growth.** `city:GetGrowth()` has `GetTurnsUntilGrowth()`, `GetTurnsUntilStarvation()`, and `GetFoodSurplus()`. Each count is -1 when it doesn't apply. `GetCityData` in `Base/Assets/UI/CitySupport.lua`, lines 474 to 486, shows the turns until growth when that count isn't -1, the turns until starvation as a loss otherwise, and 0 when both are -1. Confirmed in files and on Windows on 2026-10-24.
- **Yields.** `city:GetYield(YieldTypes.FOOD)` and the same for `PRODUCTION`, `GOLD`, `SCIENCE`, `CULTURE`, and `FAITH` return each yield per turn, with all its decimals, such as 3.8984375 for culture. The city panel rounds each one down to one decimal place with `math.floor(x * 10) / 10`, in `CitySupport.lua`, lines 316 to 332, so it shows 3.8. Confirmed in files and on Windows on 2026-10-24.

### Tile visibility

`PlayersVisibility[playerID]` has five methods. Confirmed in `SentientSystemsCore_UI` on Windows on 2026-10-24.

| Method | Result |
| --- | --- |
| `IsRevealed(plotIndex)` or `IsRevealed(x, y)` | `true` once the player has seen the tile |
| `IsVisible(plotIndex)` or `IsVisible(x, y)` | `true` while one of the player's units or cities sees the tile now |
| `GetState(plotIndex)` or `GetState(x, y)` | A `RevealedState`: `HIDDEN` is 0, `REVEALED` is 1, and `VISIBLE` is 2 |
| `IsUnitVisible(unit)` | `true` when the player can see that unit |
| `GetLayerValue(layer, x, y)` | A count for a `VisibilityLayerTypes` layer. `PlotToolTip.lua` shows the `TERRAIN` count as debug text only |

A tile under fog is revealed but not visible now. In the game below, no tile was visible without being revealed.

### What a player knows about a tile under fog

A player knows a fogged tile as it is now, not as it was when the player last saw it.

- No call gives a tile's last-seen contents. The 90 plot methods, such as `GetOwner`, `GetImprovementType`, `GetDistrictType`, and `GetResourceType`, take no player, so each returns the tile as it is now. `PlayersVisibility` has none either. Confirmed in `SentientSystemsCore_UI` on Windows on 2026-10-24.
- The game's tooltip shows those live values for every revealed tile. `ShowPlotInfo` in `Base/Assets/UI/ToolTips/PlotToolTip.lua`, lines 690 to 738, checks only `IsRevealed(plotId)`, then reads the plot in `FetchData`, lines 633 to 685. `PlotTooltip_Expansion2.lua` adds no visibility check. Confirmed in files.
- In the game, a fogged tile updates each turn, so a player sees a rival start a district, a wonder, or an improvement there. Confirmed by playing on Windows on 2026-10-24.
- Map search lists every revealed tile with the same live values. `IncrementalSearch` in `Base/Assets/UI/Popups/MapSearchPanel.lua`, line 703, checks only `IsRevealed`. Confirmed in files.

### Resources

The tooltip shows a resource only when `Players[playerID]:GetResources():IsResourceVisible(plot:GetResourceTypeHash())` is `true`. See `PlotToolTip.lua`, lines 314 to 316. Confirmed in files. On turn 14, `GetResourceType()` returned aluminum, oil, niter, and iron on fogged tiles where `IsResourceVisible` was `false`. Confirmed on Windows on 2026-10-24.

### Rival cities and units

- A rival city's banner shows when its tile is visible or revealed. `CityBanner:IsVisible` in `Base/Assets/UI/WorldView/CityBannerManager.lua`, lines 654 to 664. Confirmed in files.
- A rival unit's flag shows only on a tile that is visible now. `Refresh` in `Base/Assets/UI/UnitFlagManager.lua`, line 1778. Map search lists a unit only when its tile is visible and `IsUnitVisible(unit)` is `true`, in `MapSearchPanel.lua`, lines 467 to 474. Confirmed in files.
- `plot:GetUnitCount()` counts every unit on the tile, seen or not. On a fogged tile, it returned 1 for a rival builder whose `IsUnitVisible` was `false`. Confirmed on Windows on 2026-10-24.

### FireTuner's map reveal

FireTuner's map reveal changes the player's visibility data, not only what the screen draws. So the state after a reveal holds the whole map.

- **Reveal All** on FireTuner's **Map** panel calls `PlayersVisibility[Game.GetLocalPlayer()]:ChangeVisibilityCount(iPlotIndex, 1)` for every plot. **Unreveal All** calls it with `-1`. See `<game>\Debug\Map.ltp`. Confirmed in files.
- The panel runs in a Lua state named `TunerMapPanel`. The state appears when FireTuner opens the panel, and it stays after FireTuner closes. Confirmed on Windows on 2026-10-24.
- `ChangeVisibilityCount` is a function in `GameCore_Tuner` and `nil` in `SentientSystemsCore_UI`. Confirmed on Windows on 2026-10-24.
- After **Reveal All**, `GetState` returned `VISIBLE` for every tile, and `IsUnitVisible` was `true` for rival units that the player couldn't see before. Confirmed on Windows on 2026-10-24.
- **Unreveal All** doesn't undo **Reveal All**. The visibility counts drop back, but each tile stays revealed. A tile that was hidden before stays under fog, so the player keeps the whole map, as it is now, until a save from before the reveal loads. Confirmed on Windows on 2026-10-24.

## Method

1. Read `ShowPlotInfo` and `FetchData` in `<game>\Base\Assets\UI\ToolTips\PlotToolTip.lua`, and the visibility checks in `CityBannerManager.lua`, `UnitFlagManager.lua`, and `MapSearchPanel.lua`.
2. In `SentientSystemsCore_UI`, list the keys of `getmetatable(PlayersVisibility[0]).__index` and of `getmetatable(Map.GetPlotByIndex(0)).__index`.
3. Play until some seen tiles are under fog, with a rival city among them.
4. For each plot, from 0 to `Map.GetPlotCount() - 1`, compare `IsRevealed`, `IsVisible`, and `GetState`. For each fogged tile, print the owner, improvement, district, resource, `IsResourceVisible`, and `GetUnitCount`.
5. For each rival city and unit on a revealed tile, print `GetState` for its tile, and `IsUnitVisible` for each unit.
6. To check the map reveal, read **Reveal All** and **Unreveal All** in `<game>\Debug\Map.ltp`. Save `GetState` for every plot, and count the rival units with `IsUnitVisible`. Click **Reveal All** on FireTuner's **Map** panel, close FireTuner, and compare. Then run the panel's **Unreveal All** Lua in `TunerMapPanel` through the bridge, and compare again. Afterwards, load a save from before the reveal.

## Results

A single-player game on a 44 by 26 map, with 1,144 tiles, in `SentientSystemsCore_UI`.

| Check | Turn 1 | Turn 14 |
| --- | --- | --- |
| Revealed tiles | 23 | 161 |
| Visible tiles | 23 | 61 |
| Fogged tiles | 0 | 100 |
| `GetState` counts | 1,121 at 0 and 23 at 2 | 983 at 0, 100 at 1, and 61 at 2 |
| Visible but not revealed | 0 | 0 |

Turn 14 details:

| Tile | State | Contents |
| --- | --- | --- |
| (30,18) | Fogged | A rival's city center, Râ-Kedet, population 2. `IsCity()` is `true` and `GetOwner()` is 1 |
| (29,17) | Fogged | A rival's tile with cattle, which `IsResourceVisible` allows. `GetUnitCount()` is 1, for a rival builder whose `IsUnitVisible` is `false` |
| (8,7), (10,7), (10,9), (12,9), and (19,15) | Fogged | Unowned tiles with aluminum, oil, niter, or iron, which `IsResourceVisible` hides |
| (25,14) | Visible | A rival warrior whose `IsUnitVisible` is `true` |

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

The map reveal, on turn 14 of the same game:

| Check | Before | After **Reveal All** | After **Unreveal All** |
| --- | --- | --- | --- |
| `GetState` counts | 983 at 0, 100 at 1, and 61 at 2 | 1,144 at 2 | 1,083 at 1 and 61 at 2 |
| Tiles that differ from before | None | 1,083 | 983, each from 0 to 1 |
| Rival units the player can see | 1 | 2 | 1 |

Date checked: game files on 2026-10-24. Running game on Windows on 2026-10-24.
