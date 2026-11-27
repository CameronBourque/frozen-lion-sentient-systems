# End turn

End each agent turn once, and start the next one only when the game moves on, so the [agent loop](done.md#agent-loop) can play turn after turn. The design is in [turn-loop.md](../../design/agents/turn-loop.md). Part of [phase 2](README.md).

## Tasks

The agent loop starts a turn on every `AGENT_TURN`, `again` included. In its live check on 2026-11-26, the next `AGENT_TURN` came 0.5 s after each end turn, and the bridge played on to turn 5 with no wait. See [agent-runs.md](../../findings/agent-runs.md#agent-loop-run).


1. **Turn change.** After `end_turn`, wait for the turn number to change before the loop accepts the next `AGENT_TURN`. Never send a second end-turn request for one turn. Commit: `feat(core): wait for the turn to change after end turn`.
2. **Turn started again.** An `AGENT_TURN` that ends with `again` means the game cancelled the end of the turn, such as for a queued move that stopped short.

   Tell the model, and let it finish the turn and end it again, as [agent-runs.md](../../findings/agent-runs.md#second-run) shows a model can't tell on its own. Commit: `feat(core): tell the agent when its turn starts again`.
3. **Game load.** A `GAME_READY` from the [load signal](../../design/core/mod/lines.md#load-signal) cancels the agent's turn. Commit: `feat(core): cancel the agent's turn when a game loads`.

## Done when

In a running game, the bridge executable plays 10 turns in a row with no manual help, and the log shows each tool call with its `reason`.

## Record

- The wait for the turn to change and the `again` case in [turn-loop.md](../../design/agents/turn-loop.md#one-turn), and the game load and the wait for a silent game in [game-load.md](../../design/agents/game-load.md).
