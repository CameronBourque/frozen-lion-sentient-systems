# Action changes

An action tool returns only whether the game took the request, so the model reads the state again to learn what changed. The result could carry the part of the state that the action changed.

This debt blocks no phase or step. Pick it up when the smoke test shows that state reads after actions cost too much. [state-sections.md](state-sections.md) cuts the same cost with less work, so measure after it first.

## Now

- `sendAction` in `packages/core/bridge/src/actions/actions.ts` reads `ACTION_RESULT`, which is `{ ok: true }` or `{ ok: false, reason }`.
- `registerAction` in `packages/core/bridge/src/mcp/action.ts` makes a success return "The game took the request." An ok result means the game took the request, as the comments in `src/actions/` say, and a move may finish after the call returns ([move-unit.md](../findings/actions/move-unit.md)).
- To see a unit's new position, a city's production, or the next blocker, the model calls `get_state`, which was 247,075 to 282,928 bytes in the [measured game](../design/testing.md#state-size).

## Proposal

Give each action's result a `changed` field with the records the action touched, read after the game processes the request: the unit after a move or an order, the city after a production or a purchase, and the blockers after any action.

The core mod builds each record with the same functions as the state, so the shapes match the state's.

## Questions

- How long after a request does the game show its effect, for each kind of action? A move can take several frames. See [findings/actions/](../findings/actions/README.md).
- Does every action return the blockers, so the model knows what is left without a read?
- Is `changed` one schema for every action, or one for each kind?

## Done when

Each action tool's result holds the records it changed, in the state's shapes. A test checks that a move returns the unit at its new position.
