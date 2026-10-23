# Step 14: Agent loop

Run an agent's turn when its turn signal arrives: resolve the end-turn blockers, take the agent's other actions, and end the turn within the retry, action, and time limits. Plain code handles idle units and scouts. The design is in [turn-loop.md](../../design/agents/turn-loop.md). Part of [phase 1](README.md).

## Tasks

1. **Loop.** Add `src/agents/loop.ts`. On `AGENT_TURN` for a configured agent, it reads the state, builds the prompt, and passes the model's tool calls to the MCP server until the model calls `end_turn`. Test it with a mock model and a fake client. Commit: `feat(core): add the agent loop`.
2. **Limits.** Add the three limits from [failure handling](../../design/agents/turn-loop.md#failure-handling), with defaults in the config file: retries per action, actions per turn, and time per turn. When the loop hits a limit, it logs a warning and ends the turn. Commit: `feat(core): add turn limits`.
3. **Blockers.** When the model calls `end_turn` with a blocker left, the tool result names the blocker, and the model gets another try. When the loop hits a limit, it ends the turn with `force`, which skips any blockers left, and logs each skipped blocker as a warning. Commit: `feat(core): force the end turn at the turn limit`.
4. **Idle units and scouts.** Before the model call, fortify idle military units that stand in a city or on a fort, and set scouts to auto-explore. Leave other units to the model. Commit: `feat(core): handle idle units and scouts in plain code`.
5. **End turn.** After `end_turn`, wait for the turn number to change before the loop accepts the next `AGENT_TURN`. Never send a second end-turn request for one turn. A `GAME_READY` from step 4 cancels the turn. Commit: `feat(core): wait for the turn to change after end turn`.
6. **Game options.** Check that quick movement and quick combat are on when an agent turn starts, and log a warning when one is off. Commit: `feat(core): warn when quick movement or quick combat is off`.

## Done when

In a running game, the bridge executable plays 10 turns in a row with no manual help. The log shows each tool call with its `reason`, and no turn hits a limit.

## Record

- The loop, the limits and their defaults, and the plain-code rules, in [turn-loop.md](../../design/agents/turn-loop.md).
- The forced end turn at the limit, as a `## Decisions` row in [turn-loop.md](../../design/agents/turn-loop.md).
- Which blockers a forced end turn skips, in [game-api.md](../../findings/game-api.md#ending-the-turn).
