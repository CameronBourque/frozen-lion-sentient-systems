# Appeal layer in the state

Status: confirmed. The appeal of each revealed tile is confirmed in a running game with Gathering Storm, against the lens's counts for each level.

The calls the appeal layer of the tiles section uses, as the Appeal lens and the tooltip show it. See [design/core/mod/state.md](../../design/core/mod/state.md).

## Questions

None open.

## What we know now

### The lens and the tooltip

Confirmed in files.

- **The lens.** `MinimapPanel.lua` `SetAppealHexes` colors the tiles with `Map.GetContinentPlotsAppeal()`, which returns five lists of plot indexes: breathtaking, charming, average, uninviting, and disgusting. `ModalLensPanel.lua` only draws the key of the five levels.
- **The tooltip.** `PlotToolTip.lua` reads `plot:GetAppeal()`, a number. It shows it for a land tile and for a natural wonder, not for other water, and names the level from the first row of `GameInfo.AppealHousingChanges()` whose `MinimumValue` the number reaches.
- **The levels.** The rows are 4 breathtaking, 2 charming, -1 average, -3 uninviting, and -100 disgusting.

### The state

A revealed tile has `appeal` when the tooltip shows an appeal and it is not 0. A tile with none is average or, for water, has no appeal. The level follows from the number, so the state keeps the number only and the schema notes the levels.

The size is small, so the number is on the tile and not behind a function.

## Method

1. Send `SentientSystemsCore_Text.lua` and `SentientSystemsCore_StateTiles.lua` through the tuner as in [choices/production.md](../choices/production.md#method), step 4.
2. Call `Map.GetContinentPlotsAppeal()` and count the tiles of each list. Call `SentientSystems_GetTileStates` for the local player and count the tiles with `appeal` at each level.

## Results

A single-player game with Gathering Storm, in `SentientSystemsCore_UI`:

| Check | Result |
| --- | --- |
| The levels of the lens | Every tile in the five lists is at the level that the `MinimumValue` rows give for its `GetAppeal` |
| The counts of the state | 306 breathtaking, 405 charming, 185 uninviting, and 45 disgusting, against 304, 405, 185, and 45 in the lens |
| The 2 extra breathtaking | The 2 coast tiles of the natural wonder Ha Long Bay, each with appeal 5 and next to a neighborhood with appeal 6. The tooltip code shows them and the lens leaves them out. The tooltip of Ha Long Bay shows "Appeal: Breathtaking (5)", so the state keeps it |
| The average | 409 tiles with an appeal of -1 or above, and the other 244 land tiles of the lens at 0 are left out |
| Water | 27 lake tiles are in the lens, all with appeal 0, so average. The tooltip of a lake tile shows no appeal, so the state leaves it out |
| The size | About 17 KB for 1,350 tiles of 4,798 revealed, which is 4% of the tiles |

Date checked: game files on 2026-11-07. Running game on Windows on 2026-11-07.
