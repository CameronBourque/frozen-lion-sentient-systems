# Production actions

Status: open. Setting a city's production to a unit, a building, or a project is confirmed in a running game. Districts, wonders, purchases, and the queue aren't checked yet.

The game call that the production action wraps, with the Lua state it runs in and the reasons its checks give. The items a city can pick are in [choices/production.md](../choices/production.md).

The core mod's result format is in [design/core/mod/actions.md](../../design/core/mod/actions.md). The other actions are in the [actions index](README.md).

## Questions

None open.

## What we know now

### Setting production

`BuildUnit`, `BuildBuilding`, and `AdvanceProject` in `Base/Assets/UI/Panels/ProductionPanel.lua`, lines 293 to 420, call `CityManager.RequestOperation(city, CityOperationTypes.BUILD, parameters)`. Confirmed in files.

- The parameter that names the item is `PARAM_UNIT_TYPE`, `PARAM_BUILDING_TYPE`, `PARAM_DISTRICT_TYPE`, or `PARAM_PROJECT_TYPE`, set to the row's hash.
- `GetBuildInsertMode`, at line 2885, adds `PARAM_INSERT_MODE`. With the queue closed it is `VALUE_REPLACE_AT` with `PARAM_QUEUE_DESTINATION_LOCATION` 0, which replaces the current item. With the queue open it is `VALUE_APPEND`, or a replace at the last place when the queue is full.
- `BuildBuilding` and `ZoneDistrict` open a placement view instead of building when the row's `RequiresPlacement` is true and the city hasn't placed it. A wonder is a building row with `RequiresPlacement`.
- The action runs in `SentientSystemsCore_UI`. It finds the row by type in `GameInfo.Units`, `Buildings`, `Districts`, and `Projects`.

### The checks

- `buildQueue:CanProduce(params, true)` is the test the panel uses to list an item. The action reads a refusal as an item that isn't among the city's choices.
- `buildQueue:CanProduce(params, false, true)` returns the reasons the panel greys an item out with. A unit's `params` is a table with `UnitType` and `MilitaryFormationType`, and the other items take the hash.
- `CityManager.CanStartOperation(city, BUILD, parameters, true)` is the last check before the request. It gave no reason of its own.

## Method

1. Send the file's code to `SentientSystemsCore_UI` as in [choices/production.md](../choices/production.md#method), step 4, and call `SentientSystems_SetProduction(playerID, cityID, item)`.
2. Read the city's production before and after with `city:GetBuildQueue():GetCurrentProductionTypeHash()` and `GameInfo.Types`.

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

Date checked: 2026-11-07.
