# Fallout in the state

Status: confirmed. The `fallout` field of the tiles section is confirmed in a running game with Gathering Storm, with the files sent through the tuner. It matches the plot tooltip.

The call the fallout on each tile in the state uses, as the plot tooltip shows it. The strikes that leave it are in [actions/wmd-strikes.md](../actions/wmd-strikes.md), and the job that clears it in [actions/builder-jobs.md](../actions/builder-jobs.md#clear-fallout). See [design/core/mod/state.md](../../design/core/mod/state.md).

## Questions

None open.

## What we know now

`FetchData` in `Base/Assets/UI/ToolTips/PlotToolTip.lua` reads `Game.GetFalloutManager():GetFalloutTurnsRemaining(plot:GetIndex())`.

`View` adds `LOC_TOOLTIP_PLOT_CONTAMINATED_TEXT` with the turns when they are above 0. `DLC/Expansion2/UI/Replacements/PlotTooltip_Expansion2.lua` does the same. Confirmed in files.

The tooltip shows for any tile the player has revealed, from `IsRevealed`, so a tile under fog shows its fallout too. `MapSearchPanel.lua` and `ProductionPanel.lua` read the same call. Confirmed in files.

A nuclear device leaves 10 turns of fallout and a thermonuclear one 20, from `FalloutDuration` in `GameInfo.WMDs`. A cleared tile reads 0 at once. Confirmed on Windows on 2026-11-11.

## Method

1. Send `Scripts/State/SentientSystemsCore_StateTiles.lua` to `SentientSystemsCore_UI` without its comments, after the strikes in [actions/wmd-strikes.md](../actions/wmd-strikes.md#method).
2. In `SentientSystemsCore_UI`, count the plots where `GetFalloutTurnsRemaining` is above 0, then read the tiles section with `npm run state`.

## Results

A single-player game with Gathering Storm, after five strikes on Vietnam, in `SentientSystemsCore_UI`:

| Check | Result |
| --- | --- |
| Plots with fallout | 69, every one in Vietnam's territory |
| The tiles section after three were cleared | 66 of 4,861 revealed tiles had `fallout`, with 10 or 20 turns. The three cleared tiles had none |
| A tile under fog, Đồng Hới at (37, 28) | `fallout` 10, with `visible` false |

Date checked: game files on 2026-11-11. Running game on Windows on 2026-11-11.
