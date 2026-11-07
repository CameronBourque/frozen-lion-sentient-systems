# Production actions

Status: open. Setting a city's production to a unit, a building, a project, a district, or a wonder is confirmed in a running game. Purchases and the queue aren't checked yet.

The game call that the production action wraps, with the Lua state it runs in and the reasons its checks give. The items a city can pick are in [choices/production.md](../choices/production.md).

The core mod's result format is in [design/core/mod/actions.md](../../design/core/mod/actions.md). The other actions are in the [actions index](README.md).

## Questions

None open.

## What we know now

### Setting production

`BuildUnit`, `BuildBuilding`, `ZoneDistrict`, and `AdvanceProject` in `Base/Assets/UI/Panels/ProductionPanel.lua`, lines 293 to 420, call `CityManager.RequestOperation(city, CityOperationTypes.BUILD, parameters)`. Confirmed in files.

- The parameter that names the item is `PARAM_UNIT_TYPE`, `PARAM_BUILDING_TYPE`, `PARAM_DISTRICT_TYPE`, or `PARAM_PROJECT_TYPE`, set to the row's hash.
- `GetBuildInsertMode`, at line 2885, adds `PARAM_INSERT_MODE`. With the queue closed it is `VALUE_REPLACE_AT` with `PARAM_QUEUE_DESTINATION_LOCATION` 0, which replaces the current item. With the queue open it is `VALUE_APPEND`, or a replace at the last place when the queue is full.
- `BuildBuilding` and `ZoneDistrict` open a placement view instead of building when the row's `RequiresPlacement` is true and the city hasn't placed it. A wonder is a building row with `RequiresPlacement`.
- The action runs in `SentientSystemsCore_UI`. It finds the row by type in `GameInfo.Units`, `Buildings`, `Districts`, and `Projects`.

### Placing a district or a wonder

`ConfirmPlaceDistrict` and `ConfirmPlaceWonder` in `Base/Assets/UI/StrategicView_MapPlacement.lua`, lines 36 and 188, send the same `BUILD` operation as the panel, with `PARAM_X` and `PARAM_Y` set to the tile and the item's hash.

Both run after the player clicks a tile in the placement view. Confirmed in files.

- The tile must be one the city owns where the item can go now, the `tiles` of the [placement call](../choices/placement.md). A tile in `purchaseTiles` isn't the city's yet, so the action says to buy it first.
- A district or a wonder the city has placed already needs no tile. The panel skips the placement view when `buildQueue:HasBeenPlaced(hash)` is true, or when the city has the wonder, and the action does the same.
- `CanProduce` refuses a district or a wonder with `NO_SUITABLE_LOCATION` when it has no tile, so the action checks the tile first and asks the game only about the request itself.
- The game only allows one city at a time to build a given wonder, so a wonder another city is building is off the menu.

### The checks

- `buildQueue:CanProduce(params, true)` is the test the panel uses to list an item. The action reads a refusal as an item that isn't among the city's choices.
- `buildQueue:CanProduce(params, false, true)` returns the reasons the panel greys an item out with. A unit's `params` is a table with `UnitType` and `MilitaryFormationType`, and the other items take the hash.
- `CityManager.CanStartOperation(city, BUILD, parameters, true)` is the last check before the request. It gave no reason of its own.

## Method

1. For a district or a wonder, read its tiles with `readPlacement`.
2. Send the file's code to `SentientSystemsCore_UI` as in [choices/production.md](../choices/production.md#method), step 4, and call `SentientSystems_SetProduction(playerID, cityID, item, x, y)`. A unit, a building, and a project take no `x` and `y`.
3. Read the city's production with `city:GetBuildQueue():GetCurrentProductionTypeHash()` and `GameInfo.Types`, before the call and a second after, since the game takes the request a moment later.

   For a district, loop over `city:GetDistricts():Members()` and compare `GetX` and `GetY`.

## Results

A single-player game on turn 56, on Windows, in `SentientSystemsCore_UI`, for the first city of the local player:

| Check | Result |
| --- | --- |
| `UNIT_BUILDER`, listed and not greyed out | `{"ok":true}`. The city's production went from `PROJECT_SEND_AID` to `UNIT_BUILDER` |
| `PROJECT_SEND_AID`, already in production | `{"ok":true}`, and nothing changed |
| `UNIT_TRADER`, greyed out | The panel's reason: `Your Civilization needs more Trade Route capacity.` |
| `DISTRICT_HOLY_SITE`, greyed out | `Requires Population of 13 or greater.` |
| `UNIT_WARRIOR`, which the panel doesn't list | `UNIT_WARRIOR isn't one of this city's production choices.` |
| `UNIT_NOPE` | `UNIT_NOPE isn't a unit, building, district, wonder, or project.` and a pointer to the choice |
| `DISTRICT_NEIGHBORHOOD` with no tile, and with the tile (0, 0) | Reasons that name the missing tile and the placement call, and that the tile isn't one |
| `DISTRICT_NEIGHBORHOOD` on (43, 48), the first of Aduatuca's 7 tiles | `{"ok":true}`. A second later the city produced it, and its districts held a neighborhood at (43, 48) |
| `BUILDING_CRISTO_REDENTOR` on (42, 48), the first of Aduatuca's tiles | `{"ok":true}`. A second later the city produced it |
| `DISTRICT_HOLY_SITE` on (49, 37), a tile Lisieux could buy | `(49, 37) isn't in the city's territory yet. Buy the tile first.` |
| `BUILDING_CRISTO_REDENTOR` in another city, while Aduatuca built it | The item isn't one of the city's choices |

Date checked: 2026-11-07.
