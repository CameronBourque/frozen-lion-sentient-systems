# Rival cities and units

Status: confirmed. Revealed rival cities and visible rival units in `SentientSystems_GetState` are confirmed in a running game.

The calls the state serializer uses to list the rival cities and units one player can see, with the Lua state each one runs in.

What a player can know about each tile and the rivals on it is in [state/tile-visibility.md](tile-visibility.md). See [design/core/mod/state.md](../../design/core/mod/state.md).

## Questions

None open.

## What we know now

### Rival cities

`PlayerManager.GetAlive()` lists every living player, and each player's cities come from `GetCities():Members()`, as for the player's own. City IDs repeat across players: Rome and Râ-Kedet both had ID 65536. `city:IsCapital()` tells whether a city is its owner's capital.

The city banner reads a city's defense from its city center, for the player's own cities and for rivals', `Players[owner]:GetDistricts():FindID(city:GetDistrictID())`. That district's `GetDefenseStrength()` is the banner's defense number, rounded with `math.floor(x + 0.5)`.

`GetDamage` and `GetMaxDamage` with `DefenseTypes.DISTRICT_GARRISON` give the garrison's health, and with `DefenseTypes.DISTRICT_OUTER` the walls' health, whose most is 0 for a city with no walls.

See `CityBanner:UpdateStats` in `DLC/Expansion1/UI/CityBanners/CityBannerManager.lua`, lines 1209 to 1260. Confirmed in files and on Windows on 2026-10-24.

### Rival units

Each living player's units come from `GetUnits():Members()`, with the same calls as the player's own. Unit IDs repeat across players: player 0's scout and player 1's builder both had ID 196608, and both warriors had ID 131073.

A rival unit is visible to the player when `PlayersVisibility[playerID]:IsVisible(x, y)` and `IsUnitVisible(unit)` are both `true`. See [state/tile-visibility.md](tile-visibility.md#rival-cities-and-units). Confirmed on Windows on 2026-10-24.

## Method

1. In `SentientSystemsCore_UI`, call each city and unit call for every living player, and compare the values with the city banners and the units on the map.
2. Read the state as in [state/state.md](state.md#method), step 2, and compare it with the calls.

## Results

A single-player game on a 44 by 26 map, in `SentientSystemsCore_UI`.

`SentientSystems_GetState(0)`, on turn 14 of the same game, read through `SentientSystems_Stash` and `SentientSystems_PrintPiece`:

| Check | Result |
| --- | --- |
| Rival cities in the state, against the calls for every city | Râ-Kedet, player 1's capital, at (30,18) on a fogged tile: population 2, defense 13, garrison 200 of 200, and no walls, as its banner showed. Rome, the player's own, was left out |
| Rival units in the state, against the calls for every unit | Player 1's warrior at (25,14), on a visible tile with `IsUnitVisible` `true`, at full health. Player 1's builder at (29,17), on a fogged tile with `IsUnitVisible` `false`, was left out |

Date checked: game files on 2026-10-24. Running game on Windows on 2026-10-24.
