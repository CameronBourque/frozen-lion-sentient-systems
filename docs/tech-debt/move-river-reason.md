# Move river reason

`SentientSystems_MoveUnit` refuses a move whose path starts with a river crossing the unit can't make yet, and says the unit has no route. The game would take the move over more turns, so the refusal is wrong, and its reason doesn't name the river.

This debt blocks no phase or step. Pick it up during the [Claude Code gate](../roadmap/phase-1/claude-code-gate.md) if a model hits it, as a `fix(core):` pull request of its own.

## Now

- The route check in `packages/core/mod/Scripts/Actions/SentientSystemsCore_ActionsUnits.lua` compares the last plot of `UnitManager.GetMoveToPathEx(unit, index).plots` with the target, and returns "The unit has no route to that tile." when they differ.
- [move-unit.md](../findings/actions/move-unit.md) records that `plots` is empty for a tile with no route, such as an impassable mountain.
- In a live check on turn 1 of a duel map, a warrior with 2 of 2 moves at (16, 14) was refused a move to the plains hill at (16, 12). A river lay on the way, and crossing it takes a unit's full movement.
- A move to the next tile, (16, 13), went through. From there, the same move to (16, 12) went through, and the game queued the rest of the path for the next turn.

## Proposal

Find out what `GetMoveToPathEx` returns for a path that starts with such a crossing.

If it stops short of the target while the game can still reach it, send the request anyway, as the next tile's move showed the game takes it. If the game can't reach the tile this way, return a reason that names the river and the movement the crossing needs.

## Questions

- What does `GetMoveToPathEx` return for this path: an empty `plots`, a path that stops at the river, or one with turn markers?
- Does `WorldInput.lua` draw a path for this tile, and how does a click send the move?
- Does the same refusal happen for other crossings that take full movement, such as embarking?

## Done when

From the same setup, the move either goes through as a move over more turns, or is refused with a reason that names the river. A Lua test in `packages/core/mod/Test/` covers it, and [move-unit.md](../findings/actions/move-unit.md) records what `GetMoveToPathEx` returned.
