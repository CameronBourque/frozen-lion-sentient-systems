# Attacks

Status: open. Ranged, air, melee, city, and coastal raid attacks are confirmed in a running game. The priority target is not.

The game calls the attack actions wrap, with the Lua state each runs in and where we found each call.

"Confirmed in files", "tested", and "used by civ6-mcp" mean what they mean in [game-api.md](../game-api.md). The core mod's result format is in [design/core/mod/actions.md](../../design/core/mod/actions.md).

The move path and the war dialog are in [actions/move-unit.md](move-unit.md).

The other unit actions are in the [actions index](README.md).

## Questions

1. Does `UNITCOMMAND_PRIORITY_TARGET` mark the tile of an enemy escort, and does a request hit the escort? Support units placed under an enemy military unit, even moved onto it, didn't mark anything, so the game may need an escort formation that a spawn doesn't make. See [Attacks](#attacks).

## What we know now

### Attacks

`WorldInput.lua` and `Civ6Common.lua` make three attack calls, and `RequestMoveOperation` picks one. Confirmed in files. Confirmed on Windows on 2026-11-04:

- **Ranged and bombard.** `UnitManager.CanStartOperation(unit, RANGE_ATTACK, nil, { X, Y })` and `RequestOperation` with the same parameters.

  The UI picks it when the unit's ranged or bombard strength is above its melee strength. A crossbowman hit a unit 1 tile away, and another hit a heavy chariot 2 tiles away.
- **Air.** The same with `AIR_ATTACK`. A jet bomber hit a unit within its range of 15.
- **Melee.** `MOVE_TO` with `UnitOperationMoveModifiers.ATTACK` plus `MOVE_IGNORE_UNEXPLORED_DESTINATION`, as the move path does. A knight damaged a trebuchet on the next tile.

  A knight attacking a tile with only an enemy builder captured it: the builder became the player's, and the knight stood on the tile.
- **Targets.** `UnitManager.GetOperationTargets(unit, op)` returns `UnitOperationResults.PLOTS` and `MODIFIERS`.
- **Coastal raid.** `UNITOPERATION_COASTAL_RAID` is a ship's attack on a land tile. `WorldInput.lua` lists `GetOperationTargets(unit, COASTAL_RAID)`'s `PLOTS`, with no modifiers, and requests it with `PARAM_X` and `PARAM_Y` after the same war check as an attack.

  The UI's click tries a ranged attack, then a raid, then a move that attacks. A ranged ship's `attack` on a raid tile was refused as not a target, so the action requests the raid. Confirmed in files, and on Windows on 2026-11-06.

  A tile with `MODIFIER_IS_TARGET` holds something to hit, and the others are in range only. A tile behind a forest was missing from a crossbowman's list, so the list also reflects line of sight.
- The checks give no reasons. A unit with no attacks left failed `CanStartOperation` for every tile with an empty `FAILURE_REASONS`, and `GetAttacksRemaining()` explains it.
- `Units.GetUnitsInPlot(plot)` lists the units on a tile, and `CityManager.GetCityAt(x, y)` gives its city.
- **War.** `CombatManager.IsAttackChangeWarState` gives the same answer for an attack as for a move, and `UnitAirAttack` and the coastal raid call it the same way.

  A tile inside the borders of a player at peace returned the player, with or without a unit on it. Attacking a visible tile there is refused by the core mod. The dialog is the same as for a move, in [the war dialog](move-unit.md#the-war-dialog).
- **Priority target.** `UNITCOMMAND_PRIORITY_TARGET` is a unit command of the Rise and Fall expansion. It hits the support or civilian unit that a military unit escorts, instead of the military unit.

  `WorldInput_Expansion1.lua` lists its tiles with `UnitManager.GetCommandTargets(unit, command)`, highlights those marked with `CityCommandResults.MODIFIER_IS_TARGET`, and checks and requests it with `UnitCommandTypes.PARAM_X` and `PARAM_Y`.

  Confirmed in files. Confirmed on Windows on 2026-11-05: the check passed for spec ops, a bomber, a jet bomber, and a fighter that had moves, and failed for units with none.

  It listed every tile in range, 464 for the jet bomber, and marked none. A knight and a builder on one tile weren't marked, and the command failed for the tile.

  An enemy heavy chariot escorting a settler, in range of the jet bomber and in sight, wasn't marked either, though the air attack didn't mark it.

  The UI checks it as `CanStartCommand(unit, command, { PARAM_X, PARAM_Y })`, with no plot. With the plot as the third argument it returned `true` for an empty tile too, so only the three-argument form tells anything.

  With it, a jet fighter in range of four Cree stacks had no marked tile and failed the check. The stacks were a skirmisher with a medic, a skirmisher with a battering ram, a warrior with an observation balloon, and a warrior with a builder.

  The air attack marked 8 tiles with units. Confirmed on Windows on 2026-11-06. `RequestCommand` did nothing for an enemy unit, so a tile that is marked, and a request that works, haven't been seen.
- **City attack.** `CityManager.GetCommandTargets(city, CityCommandTypes.RANGE_ATTACK, {})` returns the tiles in `CityCommandResults.PLOTS` with `MODIFIERS`, and `CityManager.CanStartCommand` and `RequestCommand` take `{ X, Y }`.

  `CityRangeAttack` shows no war dialog. A city hit an enemy unit on the next tile, and left it with 22 damage.

## Method

Run each step through the tuner, and record the Lua state you ran it in. Steps 1 and 2 of [game-api.md](../game-api.md#method) give a unit ID.

1. **Attacks.** Call `GetOperationTargets`, the check, and the request for a ranged, an air, and a melee unit, and for a city. Read the target's damage afterward.

## Results

The bridge ran these steps in a single-player game.

| Call | Lua state | Result | Date |
| --- | --- | --- | --- |
| `SentientSystems_UnitAction` `attack` by a nuclear submarine, on a tile that isn't a target | `SentientSystemsCore_UI` | Refused with the one tile in range, (36, 36). After the change, the reason added the raid tiles | 2026-11-06 |
| The same `attack` on a raid tile, the Vietnamese Camp at (36, 37) | `SentientSystemsCore_UI` | `{"ok":true}`. The Camp was pillaged, the submarine's moves went from 5 to 0, its attack stayed, and the gold did not change | 2026-11-06 |
| `SentientSystems_UnitAction` `attack` by a crossbowman, a knight, and a jet bomber, and `SentientSystems_CityAttack` | `SentientSystemsCore_UI` | Each hit its target. The knight captured a lone builder. A tile in the borders of a player at peace returned the war reason | 2026-11-04 |

Date checked: game files on 2026-10-16 and 2026-10-23. Running game on Windows on 2026-11-04, on 2026-11-05 for the priority target, and on 2026-11-06 for the coastal raid.
