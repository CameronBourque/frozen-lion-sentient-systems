# Tourism layer in the state

Status: confirmed. The tourism of each of the player's own tiles is confirmed in a running game with Gathering Storm, against the banners' tooltips of the Tourism lens.

The calls the tourism layer of the tiles section uses, as the Tourism lens shows it. See [design/core/mod/state.md](../../design/core/mod/state.md).

## Questions

None open.

## What we know now

### The lens

`Base/Assets/UI/WorldView/TourismBannerManager.lua` draws the Tourism lens, the `Tourist_Tokens` layer, and `PlotToolTip.lua` has nothing about tourism. Confirmed in files.

- **Which tiles.** `CreateTourismBanners` walks `Map.GetCityPlots():GetPurchasedPlots(city)` of each of the local player's own cities, and puts a banner on each plot where `culture:GetTourismAt(plotID)` is above 0. A tile of another player has none.
- **The banner.** It shows `culture:GetTouristsAt(plotID)`, the visiting tourists, and `culture:GetTourismTooltipAt(plotID)` as its tooltip.
- **The tooltip.** It is one string with `[NEWLINE]` and `[ICON_Tourism]` markup, in five parts: the name of the district or wonder, the visiting tourists, a line of text, one line for each source, and the lifetime tourism.

  The sources are "Tourism added by this Wonder", "Tourism added by buildings or Great People", "Generating" for an improvement, and "Tourism from Great Works in" a building.
- **The lifetime tourism.** It is only in the last line of the tooltip. `GetLifetimeTourismAt` and similar names don't exist.

### The state

A tile of the player's own with tourism above 0 has `tourism`, `tourists` when above 0, `lifetime`, and `sources`.

The state splits the tooltip with `SentientSystems_GetTooltipLines`, which drops the icons and the empty lines. The sources are the lines after the third and before the last.

The lifetime is the last number of the last line.

A tooltip with fewer than five lines is kept whole as the sources, with no lifetime.

## Method

1. Send `SentientSystemsCore_Text.lua` and `SentientSystemsCore_StateTiles.lua` through the tuner as in [choices/production.md](../choices/production.md#method), step 4.
2. Call `SentientSystems_GetTileStates` for the local player, and compare the tiles that have `tourism` with the banners' tooltips of the lens.

## Results

A single-player game with Gathering Storm, in `SentientSystemsCore_UI`:

| Check | Result |
| --- | --- |
| The tiles with tourism | 51 of 313 of the player's own tiles, and 16 with tourists |
| The Great Lighthouse, the Colossus, and the Temple of Artemis | 11, 11, and 12 tourism, 2 tourists each, and 528, 538, and 597 lifetime, the same as the tooltips |
| A theater square | 31 tourism and 1 tourist, with 3 sources of Great Works in an Amphitheater, an Archaeological Museum, and a Broadcast Center, and 317 lifetime, the same as the tooltip |
| A mine | 1 tourism and 30 lifetime, the same as the tooltip |
| The lifetime tourism | Read for all 51 tiles |
| The size | 11.5 KB for the 51 tiles, which is 3% of the 383 KB of tiles |

Date checked: game files on 2026-11-07. Running game on Windows on 2026-11-07.
