# Map coordinates

Status: confirmed. Which way x and y run, and which tiles are neighbours, are confirmed in a running game on Windows.

How a tile's x and y map onto the screen, and which tiles touch it. The state gives every position as x and y, and the `get_state` description tells the model this.

## Questions

None open.

## What we know now

x grows to the east and y grows to the north. `UI.GridToWorld(x, y)` returns world coordinates whose X grows with x and whose Y grows with y, and the game's camera shows world +Y at the top of the screen. Confirmed on Windows on 2026-11-19.

In the Claude Code gate run, Claude Code read a bigger y as south and a smaller y as north, while it read east and west the right way.

The map is offset hexes. A row with an odd y sits half a tile east of a row with an even y, so the neighbours of a tile depend on its row. `Map.GetAdjacentPlot(x, y, direction)`, for directions 0 to 5, returns:

| Row | Same row | Rows above and below |
| --- | --- | --- |
| Odd y | x - 1 and x + 1 | x and x + 1 |
| Even y | x - 1 and x + 1 | x - 1 and x |

Confirmed on Windows on 2026-11-19.

## Method

1. In `SentientSystemsCore_UI`, print `Map.GetGridSize()`, and `UI.GridToWorld(x, y)` for tiles at the bottom, middle, and top rows and the left and right columns.
2. Print the tiles that `Map.GetAdjacentPlot(x, y, direction)` returns for directions 0 to 5, for a tile on an odd row and one on an even row.

## Results

- **`Map.GetGridSize()` on the smoke test map.** 44 by 26. Run in `SentientSystemsCore_UI` on 2026-11-19.
- **`UI.GridToWorld` for (13, 0), (13, 13), and (13, 25).** World Y of -720.5, 0.0, and 665.1, and world X of -576.0, -544.0, and -544.0. Run in `SentientSystemsCore_UI` on 2026-11-19.
- **`UI.GridToWorld` for (0, 13) and (43, 13).** World X of -1376.0 and 1375.9. Run in `SentientSystemsCore_UI` on 2026-11-19.
- **The neighbours of (13, 13).** (14, 14), (14, 13), (14, 12), (13, 12), (12, 13), and (13, 14). Run in `SentientSystemsCore_UI` on 2026-11-19.
- **The neighbours of (13, 14).** (13, 15), (14, 14), (13, 13), (12, 13), (12, 14), and (12, 15). Run in `SentientSystemsCore_UI` on 2026-11-19.

Date checked: running game on Windows on 2026-11-19.
