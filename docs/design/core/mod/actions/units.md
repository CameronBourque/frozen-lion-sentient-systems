# Unit actions

How the core mod runs the unit orders that act on the unit or its tile: moves, stances, attacks, WMD strikes, upgrades, formations, and air and transport moves. Part of the [action API](../README.md).

## Moves

`SentientSystems_MoveUnit(playerID, unitID, x, y)` in `Scripts/Actions/SentientSystemsCore_ActionsUnits.lua`, which `Scripts/Actions/SentientSystemsCore_Actions.lua` loads, moves a unit by the game's own route.

It checks the unit, the tile, the unit's moves, the war check, and the route, in that order, and returns the first failure as its reason. It never attacks and never declares war. Its reason for an air unit names rebase, deploy, and attack.

## Unit orders

`SentientSystems_UnitAction(playerID, unitID, action, x, y, type)` in the same file runs the unit orders below. They are in `Scripts/Actions/SentientSystemsCore_ActionsUnitStances.lua`, `SentientSystemsCore_ActionsUnitTiles.lua`, and the files that each order names.

Each order file registers its orders with `SentientSystems_AddUnitAction` in `SentientSystemsCore_ActionsUnits.lua`.

## Stances

`SentientSystems_UnitAction` gives a unit a stance (`fortify`, `sleep`, `skip`, `alert`, `heal`), `wake`, `delete`, or `promote`, with the promotion in `type`. The game gives no reasons for these, so the reason says what the unit is doing and whether to wake it first.

## Attacks

`attack` (with `x` and `y`) picks a melee, ranged, or air attack as the UI does, never starts a war, and lists the targets when the tile isn't one.

A ship's attack on a land tile it can raid is a coastal raid, and a refusal lists the raid tiles with the targets in range.

`priority_target` takes `x` and `y`, and is in the attacks file. A priority target hits the support or civilian unit that a military unit escorts, and the game marks the tiles that have one.

`SentientSystems_CityAttack(playerID, cityID, x, y)` in `Scripts/Actions/SentientSystemsCore_ActionsCities.lua` orders a city's shot.

## WMD strikes

`wmd_strike` (with `x`, `y`, and the device in `type`) launches a nuclear or thermonuclear device from a unit.

`SentientSystems_SiloStrike(playerID, siloX, siloY, x, y, type)` launches one from the player's missile silo, through the city that owns the silo's tile. Both are in `Scripts/Actions/SentientSystemsCore_ActionsWmds.lua`.

Each checks the device and the stockpile, the launcher, the tile, the range, and the war check, in that order. The game lists hundreds of tiles in range, so a refusal gives how many tiles the launcher can hit and how far, not the list.

A unit with no moves left can't launch, though the game's check allows it, because the unit panel shows it no strike. The [WMD launchers state](../state.md) lists what can launch each device now, and `Scripts/SentientSystemsCore_Wmds.lua` holds the rules that the state and the actions share.

## Orders on the unit's tile

`found_city`, `improve` (with the improvement in `type`), and `pillage` act on the unit's own tile. Their reasons name what is wrong with the unit or the tile, such as the city that is too close.

`pillage` takes the improvement or district first and the road when the game won't pillage the tile otherwise, so a tile with both takes two orders.

## Upgrade

`upgrade` requests the game's upgrade command, in `SentientSystemsCore_ActionsUnitUpgrade.lua`. The game's reasons name the gold, the resources, and the territory, and the core mod adds the cost of the upgrade.

The game upgrades a unit to the last unit of its chain, and one missing step blocks it. So the core mod names the unit in the chain that needs a tech or civic the player lacks.

It also says when the unit has no moves left or no upgrade, because the game gives no reason for them. A fortified unit can upgrade.

## Formations

`form_corps`, `form_army`, `enter_formation`, and `exit_formation` are in `SentientSystemsCore_ActionsUnitFormations.lua`. The first three name the other unit by its ID, and a request without it returns the units that can join.

The game gives no reasons, so the core mod says when the player lacks the civic, the unit is a civilian or has no moves, no unit is next to it, or a corps or an army can't be split.

## Air and transport

`rebase` and `deploy` are for air units, and `airlift` and `paradrop` for land units. They take `x` and `y`.

They are in `SentientSystemsCore_ActionsUnitAir.lua` and `SentientSystemsCore_ActionsUnitTransport.lua`. `SentientSystemsCore_ActionsUnitTileOrders.lua` runs them, and `priority_target` too.

The game lists the tiles each can go to, and a request for another tile returns the nearest ones that work.

The game gives no other reasons, so the core mod says when the unit is of the wrong kind, has no moves left, or has no tile to go to. One case is a paradrop from a tile that is not a city or an airstrip.

## Decisions

| Decision | Reason |
| --- | --- |
| An attack that would start a war returns a reason, and a separate action declares war | The UI asks for confirmation in a dialog that has no call to answer, and a surprise war is a decision on its own |
| A WMD strike follows the unit panel, not only the game's check | `CanStartOperation` allows a strike from a unit with no moves left, which a human can't order. The agent plays by the same rules as a human |
| A silo strike is its own function, not a unit order | A silo is an improvement that fires through its city's command, with no unit ID to pass |
| A move never attacks or declares war | The UI turns one click into a move, an attack, or a war confirmation. An agent needs each as its own deliberate action, so a move that would attack or start a war returns a reason instead |
| The core mod gives its own reason where the game gives none, such as for a stance, an upgrade, or a formation | A refusal with no reason leaves the agent to repeat the mistake |
