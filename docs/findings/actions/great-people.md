# Great person actions

Status: open. Activating a great person, a great engineer's production included, is confirmed in a running game with Gathering Storm, with the files sent through the tuner. Harvesting a wonder is confirmed in files only.

The game calls the great person orders wrap, with the Lua state each runs in and the reasons their checks give. The great people on offer are in [choices/great-people.md](../choices/great-people.md).

The core mod's result format is in [design/core/mod/actions.md](../../design/core/mod/actions.md). The other unit actions are in the [actions index](README.md).

## Questions

1. Which great person can harvest a wonder? Every great person the player had returned `false` for the loose check of `UNITCOMMAND_HARVEST_WONDER`, so no success was seen.

## What we know now

### Commands

`ACTIVATE_GREAT_PERSON` and `HARVEST_WONDER` are unit commands in `UnitCommands.xml`, with no interface mode.

`UnitPanel.lua` offers them in its generic loop: it checks `CanStartCommand(unit, hash, true)`, then for real with results, and `OnUnitActionClicked` calls `UnitManager.RequestCommand(unit, hash)` with no parameters. Confirmed in files.

- A great person's use is `activate`, whatever the class. The action name on the button comes from `UnitOperationResults.ACTION_NAME`, which was "Retire" for generals and admirals, "Activated Effect" for engineers and merchants, and "Create Great Work" for a writer.
- The real check gives reasons in `UnitCommandResults.FAILURE_REASONS`, such as "Must be on a tile with no military units.", "Must be on a tile you own.", "Must be on a completed Harbor.", and "Must be on a tile no player owns.".

  The action returns them joined.
- A great engineer's production goes to a wonder under construction by activate. 

  Isidore of Miletus and Imhotep each added production to a wonder that way, for one of their charges. A great person stacked with embarked civilians failed the loose check with no reason, as the game allows only units of one kind to stack.

  `UNITCOMMAND_BUILDING_PRODUCTION`, `DISTRICT_PRODUCTION`, `WONDER_PRODUCTION`, and `PROJECT_PRODUCTION` stayed `false` for every great person, as in [builder-jobs.md](builder-jobs.md), so `add_production` is for builders.
- `unit:GetGreatPerson()` gives the class and individual and `GetActionCharges()`. The action tells a great person apart by a class in `GameInfo.GreatPersonClasses`.

## Method

1. Send the files' code to `SentientSystemsCore_UI` as in [choices/production.md](../choices/production.md#method), step 4, and call `SentientSystems_UnitAction(playerID, unitID, "activate")` for a great person.
2. To list what the great people can do, loop over the player's units with `GetGreatPerson()` and call `UnitManager.CanStartCommand(unit, hash, false, true)` for each command's hash from `GameInfo.UnitCommands`, and read `UnitCommandResults.FAILURE_REASONS` in the results.
3. To move a unit, send `UnitManager.PlaceUnit(unit, x, y)` in `GameCore_Tuner`, then `UnitManager.RestoreMovement(unit)`, because the placement uses up its moves.

## Results

A single-player game on turn 56, on Windows, in `SentientSystemsCore_UI`:

| Check | Result |
| --- | --- |
| `activate` for Leif Erikson, a Great Admiral | `{"ok":true}`, and the unit was gone after |
| Hanno the Navigator | "Must be on a tile with no military units." |
| Gaius Duilius | "Must be on a tile with a naval military unit. Must be on a tile with a military unit that is not a Corps or an Army." |
| Zheng He | "Must be on a tile you own. Must be on a completed Harbor." |
| Isidore of Miletus, a Great Engineer on the tile of Statue of Liberty, while stacked with embarked civilians | The loose check was `false`, with no reason, and the action says it can't activate now |
| Isidore again, after the builder and the Military Engineer on its tile moved away | `{"ok":true}`. The unit stayed with 2 of 3 charges, and the wonder had 107 production |
| Imhotep and James of St George on the tile of Statue of Zeus, stacked | The check was `false` with no reason for both. James shows in the game as a generic Great Engineer, spawned in an earlier step |
| Imhotep on the same tile, later | The check was `true`, `activate` returned ok, and Statue of Zeus went from 0 to 175 production, with 2 of 3 charges left. The earlier failure is taken to be a stack of civilians |
| Imhotep activated again on that tile | `activate` returned ok, with 1 of 3 charges left, and the city's production was then a Factory at 92 of 165. Whether Statue of Zeus finished was not checked. `HARVEST_WONDER` stayed `false` for him |
| A sleeping great engineer | The unit is sleeping, and to wake it first |
| A musketman | The unit is busy with an order |

Five great people could activate where they stood: Leif Erikson, Rajendra Chola, Artemisia, Hannibal Barca, and El Cid. The rest gave a reason, except Isidore of Miletus until the units stacked with it moved.

Date checked: game files on 2026-11-06. Running game on Windows on 2026-11-06.
