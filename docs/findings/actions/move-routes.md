# Move routes

Status: open. Checking a route, the gap after founding a city, and moves through unrevealed tiles are confirmed in a running game. What triggers the gap is not known.

The game call that draws a unit's route, and what the game does with a queued move whose route breaks. How a unit moves, and the move checks, are in [move-unit.md](move-unit.md).

## Questions

- What makes `GetMoveToPathEx` return no path right after a city is founded, in some runs and not others?

## What we know now

### Checking a route

`UnitManager.GetMoveToPathEx(unit, plotIndex)` returns the route the game's cursor draws, as `WorldInput.lua` reads it. Confirmed in files.

The table has `plots`, the plot indexes from the first step to the target, `turns`, the turn each step is reached, and `obstacles`, `exitPortals`, and `entrancePortals`.

It is the only check we found that covers a move over more than one turn. Confirmed on Windows on 2026-11-04, with a scout on turn 55:

- For a reachable tile the last plot is the target. A tile 9 away gave 10 plots and 4 turns.
- For a tile with no route, such as an impassable mountain, `plots` is empty.
- For the unit's own tile, `plots` is empty.
- A scout that could embark got a route to an ocean tile, so the route follows what the unit can enter.
- A path that crosses a river, or ends on a hill or forest that costs more than the moves left, still ends on the target. Its `turns` give the next turn for that step, and the game queues the move. Confirmed on Windows on 2026-11-19.

Right after a city is founded, the call sometimes returns an empty `plots`, or nothing at all, for a tile the unit can reach. A few seconds later the path is back.

It happened in 2 of 5 runs from the same turn 1 state, and we found no setting that triggers it: window focus, a fresh boot, and a reload made no difference.

In the Claude Code gate run, the agent founded its capital and moved its warrior at once, and the move was refused. `CanStartOperation` passes a move to a mountain too, so it doesn't mark the tiles with no route. Confirmed on Windows on 2026-11-19.

A `MOVE_TO` request for a far tile starts at once and uses the moves left. A scout with 3 moves, asked to move to a tile 2 away, moved one tile and stopped with 0 moves. A unit with 0 moves left is refused by our own check, because the request would only queue. Confirmed on Windows on 2026-11-04.

### Moves through unrevealed tiles

`GetMoveToPathEx` treats unrevealed tiles as land the unit can cross. On turn 4 of the Claude Code gate game, a warrior got a 3-turn path to unrevealed coast at (9, 17), through more unrevealed coast, and the move returned `{"ok":true}`.

The warrior walked two tiles and revealed the coast. Then the path to (9, 17) was empty, but `UnitManager.GetQueuedDestination(unit)` still gave its plot index. It gives `nil` for a unit with no queued move.

On the next turn the warrior stood still with all its moves and kept the destination. The end turn blockers didn't list it as needing orders. Confirmed on Windows on 2026-11-19.

- `Events.UnitMoveComplete(playerID, unitID, x, y)` fired once, when the warrior stopped with 0 moves, and the destination was still queued then. `UnitPanel.lua` listens to it too.
- `UnitManager.RequestCommand(unit, UnitCommandTypes.CANCEL)` cleared the destination by the next call, not in the same one. Then the blockers listed the warrior as needing orders.

Confirmed on Windows on 2026-11-19.

## Method

Run each step through the tuner, in `SentientSystemsCore_UI`. Get a unit as in step 1 of [move-unit.md](move-unit.md#method).

1. **Check a route.** Call `UnitManager.GetMoveToPathEx(unit, plotIndex)` for a tile 9 away, an impassable tile, the unit's own tile, and a hill across a river. Repeat it in the call after a `FOUND_CITY` request.

   Compare the last plot with the target, then call `MoveUnit` for each and read the unit's position and moves.
2. **Move into unrevealed tiles.** Pick an unrevealed tile behind unrevealed water, check it with `PlayersVisibility[playerID]:IsRevealed(x, y)`, and move a land unit there.

   Record the path, the result, and `GetQueuedDestination` after the move, on the next turn, and after a `CANCEL` command. Add a listener to `Events.UnitMoveComplete` first, and record each call.

## Results

- **`GetMoveToPathEx` for a reachable tile 9 away, and for a mountain.** 10 plots ending at the target with 4 turns, and an empty `plots`. Run in `SentientSystemsCore_UI` on 2026-11-04.
- **`GetMoveToPathEx` for a warrior with 2 moves, to a grass hill 2 tiles away across a river.** 3 plots ending at the target, with turns 1, 1, 2. With 1 move left, one tile closer: 2 plots ending at the target, with turns 1, 2, and the move queued. Run in `SentientSystemsCore_UI` on 2026-11-19.
- **The same path in the next call after a `FOUND_CITY` request, on turn 1.** Run 1: empty `plots`, with the city not yet counted. Run 2: `GetReachableMovement` returned `nil`.

  Runs 3 to 5, focused, unfocused, and after a fresh boot: the full path every 50 ms, and the city counted within 100 ms. Run in `SentientSystemsCore_UI` on 2026-11-19.
- **A warrior's move to unrevealed coast at (9, 17), from (13, 17), on turn 4.** A path of 5 plots with turns 1, 1, 1, 2, 3, and `{"ok":true}`. The warrior stopped at (11, 17) with 0 moves.

  The coast was revealed, the path was empty, and the destination was still queued. Run in `SentientSystemsCore_UI` on 2026-11-19.
- **The same warrior on turn 5.** At (11, 17) with 2 of 2 moves, the destination still queued, and not among the units needing orders. After `CANCEL`: no destination, and listed as needing orders. Run in `SentientSystemsCore_UI` on 2026-11-19.
- **The same move with the core mod's cancel, from a reload of turn 4.** The warrior stopped at (11, 17) with no destination, and the events held its `moveCancelled` message.

  On turn 5 it was awake and the only unit needing orders. A scout sent 4 tiles away showed its `destination` in the state. Run in `SentientSystemsCore_UI` on 2026-11-19.
- **`SentientSystems_MoveUnit` for a tile 2 away.** `ok`. The scout moved one tile and stopped with 0 moves. Run in `SentientSystemsCore_UI` on 2026-11-04.

Date checked: running game on Windows, routes on 2026-11-04, and routes after founding a city and moves into unrevealed tiles on 2026-11-19.
