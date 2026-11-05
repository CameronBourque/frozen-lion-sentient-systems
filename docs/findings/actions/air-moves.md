# Air moves

Status: confirmed. Rebase, deploy, airlift, and paradrop are confirmed in a running game.

The game calls the air move actions wrap, with the Lua state each runs in and where we found each call. "Confirmed in files", "tested", and "used by civ6-mcp" mean what they mean in [game-api.md](../game-api.md). The core mod's result format is in [design/core/mod/actions.md](../../design/core/mod/actions.md).

The other unit actions are in the [actions index](README.md).

## Questions

None open.

## What we know now

### Air moves

`WorldInput.lua` makes four air calls, each in an interface mode that the player clicks a tile in. Rebase and deploy are unit operations: `AirUnitReBase` and `AirUnitDeploy` check `CanStartOperation(unit, REBASE or DEPLOY, nil, { PARAM_X, PARAM_Y })` and request it with the same parameters. Airlift is the unit command `AIRLIFT`, and `UnitAirlift` uses `UnitCommandTypes.PARAM_X` and `PARAM_Y`. Paradrop is the command `PARADROP` of the Rise and Fall expansion, and `UnitParadrop` in `WorldInput_Expansion1.lua` does the same. Each mode lists its tiles with `UnitManager.GetOperationTargets` or `GetCommandTargets`, as `PLOTS` plot indexes. Confirmed in files. Confirmed on Windows on 2026-11-05:

- **Rebase.** A jet fighter at a city listed 13 tiles up to 20 away, such as cities, an aerodrome, and an airstrip. It moved to a city 7 tiles away and had no moves left, and the check then failed. A plain land tile failed.
- **Deploy.** The same fighter listed 218 tiles up to 10 away, including plain land. The request kept the unit in its city and set its activity to `ACTIVITY_INTERCEPT`. It passed with no moves left.
- **Airlift.** An infantry unit in a city with an airport listed 12 tiles around the aerodrome of the other city with an airport, and landed on one of them with no moves left. Infantry on the aerodrome tile and on a tile next to it listed targets too, and a city with no airport listed none. A frigate on the water next to an aerodrome with an airport listed none, where infantry on the aerodrome listed 9. In `GameCore_Tuner`, `WorldBuilder.CityManager():CreateDistrict` and `CreateBuilding` built the aerodrome, the hangar, and the airport.
- **Paradrop.** Spec ops, the only unit with `CLASS_PARADROP` in `GameInfo.TypeTags`, listed about 130 tiles up to 7 away from a city, and about 200 from a tile with an airstrip. It landed 3 tiles away with no moves left. Infantry failed, and so did spec ops on a bare tile.
- Airlift and paradrop are for land units, and air units rebase instead. A unit with no moves failed rebase, airlift, and paradrop. `CanStartCommand(unit, command, nil, parameters)` ignored the tile, and `CanStartCommand(unit, command, parameters)` checked it.
- The checks give no reasons and no results besides the tiles.

## Method

Run each step through the tuner, and record the Lua state you ran it in. Steps 1 and 2 of [game-api.md](../game-api.md#method) give a unit ID.

1. **Air moves.** List the targets, check with a tile, and request each order with air units, a spec ops unit, and an infantry unit in cities with and without an airport, and read the unit's tile, moves, and activity afterward.

## Results

The bridge ran these steps in a single-player game.

| Call | Lua state | Result | Date |
| --- | --- | --- | --- |
| `SentientSystems_UnitAction` for `rebase`, `deploy`, `airlift`, and `paradrop` | `SentientSystemsCore_UI` | A fighter rebased and deployed, an infantry unit airlifted, and a spec ops unit paradropped. Each other case gave a reason: a tile out of range, a unit of the wrong kind, no moves, no airport, and no city or airstrip | 2026-11-05 |

Date checked: game files on 2026-10-16 and 2026-10-23. Running game on Windows on 2026-11-05.
