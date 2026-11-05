# Formations

Status: confirmed. The corps, army, and formation commands are confirmed in a running game.

The game calls the formation actions wrap, with the Lua state each runs in and where we found each call. "Confirmed in files", "tested", and "used by civ6-mcp" mean what they mean in [game-api.md](../game-api.md). The core mod's result format is in [design/core/mod/actions.md](../../design/core/mod/actions.md).

The other unit actions are in the [actions index](README.md).

## Questions

None open.

## What we know now

### Formations

`GameInfo.UnitCommands` has `ENTER_FORMATION`, `EXIT_FORMATION`, `FORM_CORPS`, and `FORM_ARMY`. The corps needs the civic Nationalism and the army needs Mobilization, as `PrereqCivic` says in `UnitCommands.xml`. For `ENTER_FORMATION`, `UnitPanel.lua` calls `CanStartCommand(unit, hash, nil, true)`, reads the units in `UnitCommandResults.UNITS`, each with a player and an ID, and adds one button for each. `OnUnitActionClicked_EnterFormation` requests the command with `PARAM_UNIT_PLAYER` and `PARAM_UNIT_ID` of the chosen unit. A corps and an army use an interface mode. `WorldInput.lua` takes each unit on the clicked tile, checks `FORM_CORPS` or `FORM_ARMY` with those two parameters, and requests it. `UnitManager.GetCommandTargets(unit, command)` returns the same list in `UNITS`. Exit has no parameters, and the panel's loop requests it with `RequestCommand(unit, command)`. Confirmed in files. Confirmed on Windows on 2026-11-05:

- **Corps.** The other unit has to be of the same kind and on an adjacent tile. Three knights on one tile didn't list each other, and a knight next to them listed all three. A knight formed a corps with the knight next to it. The other knight was gone, `GetMilitaryFormation()` was 1, and the unit had no moves left. A unit with no moves failed the loose check and had no targets. A partner with no moves was still listed. Two builders next to each other failed, and their `FormationClass` is `FORMATION_CLASS_CIVILIAN`.
- **Army.** The player had Nationalism and lacked Mobilization, and the check failed. After `SetCivic(index, true)` in `GameCore_Tuner`, a corps listed an adjacent knight that was not in a formation, and that knight listed the corps. They formed an army, with `GetMilitaryFormation()` of 2. The other knight was gone.
- **Enter and exit.** A knight and a crossbowman on a tile with a builder listed the builder, and the builder listed them. Two knights on a tile didn't list each other. After a knight entered, both units had `GetFormationUnitCount()` of 2 on the same tile, and exit was allowed for both. Exit took them back to 1. The plain check of `ENTER_FORMATION` returned false where the check with results returned true. A medic, which is a support unit, listed the knights and the crossbowman but not the builder, and the builder did not list the medic. A frigate on a coast tile listed an embarked builder and an embarked knight, and each of them listed the frigate, but two frigates didn't list each other. A medic with a knight and a frigate with the builder entered through the action, and each pair's count rose to 2.
- A corps and an army failed the check for exit with moves restored, and `RestoreMovement` in `GameCore_Tuner` gave the moves back.
- The checks give only the `UNITS` list and no reasons. A request changed the units after the call returned, not inside it.

## Method

Run each step through the tuner, and record the Lua state you ran it in. Steps 1 and 2 of [game-api.md](../game-api.md#method) give a unit ID.

1. **Formations.** List `GetCommandTargets` for each command, check with the other unit's player and ID, request it, and read `GetMilitaryFormation()`, `GetFormationUnitCount()`, and the moves afterward. In `GameCore_Tuner`, `InitUnit` spawns the units, `RestoreMovement` and `ChangeMovesRemaining` set the moves, and `SetCivic` gives a civic.

## Results

The bridge ran these steps in a single-player game.

| Call | Lua state | Result | Date |
| --- | --- | --- | --- |
| `SentientSystems_UnitAction` for `form_corps`, `form_army`, `enter_formation`, and `exit_formation` | `SentientSystemsCore_UI` | A musketman formed a corps and then an army, and a knight entered and left a builder's tile formation. Each other case gave a reason: no unit named, a unit that can't join, a builder, no moves, a corps that can't exit, and a missing civic | 2026-11-05 |

Date checked: game files on 2026-10-16 and 2026-10-23. Running game on Windows on 2026-11-05.
