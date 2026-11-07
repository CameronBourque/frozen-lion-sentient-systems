# Continents layer in the state

Status: confirmed. The continent of each revealed tile and the continents' names are confirmed in a running game with Gathering Storm, against the lens's lists.

The calls the continents layer uses, as the Continent lens and the tooltip show it. See [design/core/mod/state.md](../../design/core/mod/state.md).

## Questions

None open.

## What we know now

### The lens and the tooltip

Confirmed in files.

- **The lens.** `MinimapPanel.lua` `SetContinentHexes` walks `Map.GetContinentsInUse()` and colors each continent's `Map.GetVisibleContinentPlots(id)`. `ModalLensPanel.lua` `ShowContinentLensKey` lists the name of each continent that has such plots, from `GameInfo.Continents[id].Description`.
- **The tooltip.** `PlotToolTip.lua` reads `plot:GetContinentType()` and shows the continent's `Description` as "Continent". It leaves the line out for -1, which is a tile with no continent. A lake tile has one.

### The state

A revealed tile has `continent`, the index that `GetContinentType` returns, and the state leaves it out for -1. A `continents` section lists each continent with a revealed tile, with its `index`, `type`, and `name`, in the game's language.

The tile holds the index, not the type, to keep the tiles small. The `continents` list gives its type and name. What matters about a continent is whether two tiles are on the same one, which some policies and other mechanics depend on, and an index shows that.

## Method

1. Send `SentientSystemsCore_Text.lua`, `SentientSystemsCore_StateTiles.lua`, and `SentientSystemsCore_StateContinents.lua` through the tuner as in [choices/production.md](../choices/production.md#method), step 4.
2. Count the plots in each list of `Map.GetVisibleContinentPlots`, and compare them with the revealed tiles' `GetContinentType`. Call `SentientSystems_GetTileStates` and `SentientSystems_GetContinentStates` and compare the counts and the names with the lens's key.

## Results

A single-player game with Gathering Storm, in `SentientSystemsCore_UI`:

| Check | Result |
| --- | --- |
| The lens against `GetContinentType` | Every revealed tile in the lens's lists has the same continent in `GetContinentType`, and every revealed tile with a continent is in a list. No tile differs |
| The continents | 6 in use, all with revealed tiles: Antarctica, Avalonia, Kumari Kandam, Laurasia, Novopangaea, and Pangaea Ultima |
| The tiles | 167, 809, 190, 80, 184, and 162 tiles by continent, the same as the lens's lists, and 3,206 revealed tiles with none |
| A lake tile | The tooltip shows "Continent: Avalonia" for a lake tile, and the state gives it that continent |
| The size | About 24 KB for the 1,592 tiles with a continent, which is 6% of the tiles, and under 1 KB for the list |

Date checked: game files on 2026-11-07. Running game on Windows on 2026-11-07.
