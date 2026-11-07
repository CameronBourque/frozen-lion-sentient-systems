# State: great works and map layers

Add what an agent needs to place great works, and the tourism, appeal, and continent of each tile, before it plans. None of them is in the state today. Part of [phase 1](README.md).

## Tasks

1. **Great work slots.** Add every great work slot of the player's cities as one flat list. Each slot has its kind, such as writing, art, artifact, music, or relic, the city and building that hold it, and the great work in it when there is one, with the work's name and yields.

   Add the building's theming progress, and the totals that the screen shows: the great works, the display spaces, and what they provide.

   Read the calls from `GreatWorksOverview.lua` and `GreatWorksSupport.lua`, and the Expansion 2 replacement. Commit: `feat(core): add the great work slots to the state`.
2. **Where a great work can move.** Add, for each great work, the slots in the player's other cities that take it, because a work only fits a slot of its kind. The move itself is an action in [Action API: great works](action-api-great-works.md).

   Measure the size first. If the list is too large for the state, make it a function for one work that the bridge calls, as the available routes are. Commit: `feat(core): add the great work moves to the state`.
3. **Tourism layer.** Add each tile's tourism as the tourism lens and the tile's tooltip show it: the visiting tourists, the tourism the tile gives each turn and what gives it, such as a district, a wonder, great works in a building, or an improvement, and the lifetime tourism of the tile.

   Read the calls from `TourismBannerManager.lua` and `PlotToolTip.lua`. Commit: `feat(core): add the tourism layer to the state`.
4. **Appeal layer.** Add each tile's appeal as the appeal lens shows it. Read the calls from `ModalLensPanel.lua` and `PlotToolTip.lua`. Commit: `feat(core): add the appeal layer to the state`.
5. **Continents layer.** Add each tile's continent, and the name of each continent, as the continents lens shows them. Read the calls from `ModalLensPanel.lua` and `PlotToolTip.lua`. Commit: `feat(core): add the continents layer to the state`.

Each layer covers only the tiles the player has revealed, as the tiles section does. Measure each layer's size before you choose its place. A short value goes on the tile entry and is left out where it is 0, and a layer that is too large becomes a function for one area.

## Done when

In a running game, the great work slots match the Great Works screen, with its slots, works, and totals, and each layer matches the tooltip and the lens of at least one tile of each kind.

## Record

- Each section's calls and results, in a findings file of its own in [findings/state/](../../findings/state/README.md), with a row in its index.
- Each section, in [design/core/mod/state.md](../../design/core/mod/state.md).
- The parts of each section, listed in the `## Parts of a state section` table in the [core README](../../../packages/core/README.md).
