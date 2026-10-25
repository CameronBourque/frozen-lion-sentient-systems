# Tile visibility

Status: open. What a player knows about each tile, the visibility layers, and what FireTuner's map reveal changes are confirmed from the game's files and in a running game. Whether a layer keeps what the player last saw on a fogged tile is not checked.

What a player can know about each tile and the rivals on it, and the calls that give the core mod that knowledge. The state serializer builds its tiles and rivals from these facts. The calls it makes are in [game-state.md](game-state.md).

## Questions

1. Does `PlayerManager.SetLocalObserverTo(PlayerTypes.OBSERVER)` show the whole map without changing any player's `PlayersVisibility`? Do the action API's requests still work while it's on? **Set Observer To OBSERVER** on FireTuner's **Map** panel calls it, in `<game>\Debug\Map.ltp`. Test in phase 4.

## What we know now

### Visibility calls

`PlayersVisibility[playerID]` has five methods. Confirmed in `SentientSystemsCore_UI` on Windows on 2026-10-24.

| Method | Result |
| --- | --- |
| `IsRevealed(plotIndex)` or `IsRevealed(x, y)` | `true` once the player has seen the tile |
| `IsVisible(plotIndex)` or `IsVisible(x, y)` | `true` while one of the player's units or cities sees the tile now |
| `GetState(plotIndex)` or `GetState(x, y)` | A `RevealedState`: `HIDDEN` is 0, `REVEALED` is 1, and `VISIBLE` is 2 |
| `IsUnitVisible(unit)` | `true` when the player can see that unit |
| `GetLayerValue(layer, plotIndex)` | The value of one of the player's `VisibilityLayerTypes` layers on a plot. See [Visibility layers](#visibility-layers) |

A tile under fog is revealed but not visible now. In the game below, no tile was visible without being revealed.

### What a player knows about a tile under fog

A player knows a fogged tile as it is now, not as it was when the player last saw it.

- No plot call gives a tile's last-seen contents. The 90 plot methods, such as `GetOwner`, `GetImprovementType`, `GetDistrictType`, and `GetResourceType`, take no player, so each returns the tile as it is now. `PlayersVisibility` holds the player's own record for resources, improvements, and routes only, in its layers. See [Visibility layers](#visibility-layers). Confirmed in `SentientSystemsCore_UI` on Windows on 2026-10-24.
- The game's tooltip shows those live values for every revealed tile. `ShowPlotInfo` in `Base/Assets/UI/ToolTips/PlotToolTip.lua`, lines 690 to 738, checks only `IsRevealed(plotId)`, then reads the plot in `FetchData`, lines 633 to 685. `PlotTooltip_Expansion2.lua` adds no visibility check. Confirmed in files.
- In the game, a fogged tile updates each turn, so a player sees a rival start a district, a wonder, or an improvement there. Confirmed by playing on Windows on 2026-10-24.
- Map search lists every revealed tile with the same live values. `IncrementalSearch` in `Base/Assets/UI/Popups/MapSearchPanel.lua`, line 703, checks only `IsRevealed`. Confirmed in files.

### Visibility layers

`VisibilityLayerTypes` has `TERRAIN`, `RESOURCES`, `IMPROVEMENTS`, `ROUTES`, `STEALTH`, and `STEALTH0`. `PlayersVisibility[playerID]:GetLayerValue(layer, plotIndex)` and `PlayerVisibilityManager.GetPlayerVisibility(playerID):GetLayerValue(layer, plotIndex)` return the player's value for a layer on a plot. Confirmed on Windows on 2026-10-24.

- `TERRAIN` holds a count. It was 7 on Rome's tile and 0 on fogged tiles. `PlotToolTip.lua` shows it as debug text.
- `RESOURCES`, `IMPROVEMENTS`, and `ROUTES` hold an index in `GameInfo.Resources`, `GameInfo.Improvements`, or `GameInfo.Routes`, or -1. They hold what the player's units and cities have seen. `RESOURCES` also leaves out a resource that the player's techs don't reveal, such as coal on a tile that was visible now.
- `STEALTH` and `STEALTH0` returned nothing on the plots checked.
- The map draws resource icons from the `RESOURCES` layer, in `GetNonEmptyAt` in `Base/Assets/UI/WorldViewIconsManager.lua`, line 301. It hides the icon on a city or district tile. The tooltip reads the live plot instead. Confirmed in files.
- Tiles revealed without the player seeing them, such as the tiles around a rival's city that the player hasn't visited, have empty layers. Their resources show in the tooltip but not as map icons, and their roads show in the tooltip only. Confirmed on Windows on 2026-10-24.
- Not checked: whether a layer keeps what the player last saw on a fogged tile, or follows the tile's changes. No tile on the test save had an improvement.

### Resources

The tooltip shows a resource only when `Players[playerID]:GetResources():IsResourceVisible(plot:GetResourceTypeHash())` is `true`, on any revealed tile, whatever the `RESOURCES` layer holds. See `PlotToolTip.lua`, lines 314 to 316. Confirmed in files. On turn 14, `GetResourceType()` returned aluminum, oil, niter, and iron on fogged tiles where `IsResourceVisible` was `false`. Confirmed on Windows on 2026-10-24.

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

1. Read `ShowPlotInfo` and `FetchData` in `<game>\Base\Assets\UI\ToolTips\PlotToolTip.lua`, and the visibility checks in `CityBannerManager.lua`, `UnitFlagManager.lua`, `MapSearchPanel.lua`, and `WorldViewIconsManager.lua`.
2. In `SentientSystemsCore_UI`, list the keys of `getmetatable(PlayersVisibility[0]).__index`, of `getmetatable(Map.GetPlotByIndex(0)).__index`, and of `VisibilityLayerTypes`.
3. Play until some seen tiles are under fog, with a rival city among them.
4. For each plot, from 0 to `Map.GetPlotCount() - 1`, compare `IsRevealed`, `IsVisible`, and `GetState`. For each fogged tile, print the owner, improvement, district, resource, `IsResourceVisible`, and `GetUnitCount`.
5. For each rival city and unit on a revealed tile, print `GetState` for its tile, and `IsUnitVisible` for each unit.
6. For each revealed plot, compare the `RESOURCES`, `IMPROVEMENTS`, and `ROUTES` layers with `GetResourceType()`, `GetImprovementType()`, and `GetRouteType()`. Hover over each tile that differs, and note what the tooltip and the map show.
7. To check the map reveal, read **Reveal All** and **Unreveal All** in `<game>\Debug\Map.ltp`. Save `GetState` for every plot, and count the rival units with `IsUnitVisible`. Click **Reveal All** on FireTuner's **Map** panel, close FireTuner, and compare. Then run the panel's **Unreveal All** Lua in `TunerMapPanel` through the bridge, and compare again. Afterwards, load a save from before the reveal.

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

The visibility layers, on turn 14 of the same game:

| Check | Result |
| --- | --- |
| `RESOURCES` layer against the live resource with `IsResourceVisible`, on every revealed plot | Equal on 157 plots. The layer was -1 on the 4 resource tiles around Râ-Kedet, which the tooltip showed: cattle at (29,17), maize at (31,18), incense at (29,19), and copper at (30,19). The map drew no icons there |
| `RESOURCES` layer against the live resource without `IsResourceVisible` | Equal on 151 plots. It also differed on the 6 resources hidden by tech |
| `ROUTES` layer against `GetRouteType()` | Equal on 160 plots. On Râ-Kedet's city tile, the layer was -1 and the live route was 0, which the tooltip showed as **Ancient Road** |
| `IMPROVEMENTS` layer against `GetImprovementType()` | Equal on all 161 plots, all with no improvement |

The map reveal, on turn 14 of the same game:

| Check | Before | After **Reveal All** | After **Unreveal All** |
| --- | --- | --- | --- |
| `GetState` counts | 983 at 0, 100 at 1, and 61 at 2 | 1,144 at 2 | 1,083 at 1 and 61 at 2 |
| Tiles that differ from before | None | 1,083 | 983, each from 0 to 1 |
| Rival units the player can see | 1 | 2 | 1 |

Date checked: game files on 2026-10-24. Running game on Windows on 2026-10-24.
