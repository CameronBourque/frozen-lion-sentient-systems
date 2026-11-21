# Action changes

Make each action tool's result carry the records the action changed, so the agent sees the effect of an action without reading the whole state again. The prompt keeps one cached state per turn, as [prompt.md](../../design/agents/prompt.md#one-state-per-turn) describes. Part of [phase 2](README.md).

Today `sendAction` in `src/actions/actions.ts` reads `{ ok: true }` or `{ ok: false, reason }`, and `registerAction` in `src/mcp/action.ts` turns a success into "The game took the request." A move can finish after the call returns, as [move-unit.md](../../findings/actions/move-unit.md) shows.

## Tasks

1. **Timing.** Find how long after a request the game shows its effect, for a move, a unit order, a production change, a purchase, and a choice such as a tech. Record it in a finding in [findings/actions/](../../findings/actions/README.md). Commit: `docs: record when an action's effect shows`.
2. **Design.** Add a `changed` field to the action result in [actions/README.md](../../design/core/mod/actions/README.md#results). It holds the records the action touched, in the state's shapes, built with the state's own functions.

   The records are the unit after a move or an order, the city after production or a purchase, and the blockers after every action. Say how the core mod waits for the effect from task 1. Commit: `docs: design the action changes`.
3. **Units.** Return the changed unit from the unit actions, and show `changed` as JSON in the tool result in place of "The game took the request." Commit: `feat(core): report the unit an action changed`.
4. **Cities.** Return the changed city from the city actions. Commit: `feat(core): report the city an action changed`.
5. **Blockers.** Return the blockers after every action. Update `rules/play.md` to say an action's result shows what changed. Commit: `feat(core): report the blockers after each action`.

## Done when

In a running game, a `move_unit` result shows the unit at its new position, and a `set_production` result shows the city's new production. Each result also holds the blockers. Tests cover each kind of action with the fake game.

## Record

- When each kind of action shows its effect, in [findings/actions/](../../findings/actions/README.md).
- The `changed` field, in [actions/README.md](../../design/core/mod/actions/README.md#results) and [mcp-server.md](../../design/core/mcp-server.md).
