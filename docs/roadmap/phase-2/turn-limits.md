# Turn limits

Limit the retries, actions, and time of an agent turn, so one stuck turn can't stop a game. The design is in [failure handling](../../design/agents/turn-loop.md#failure-handling). Part of [phase 2](README.md).

## Tasks

1. **Limits.** Add the three limits, with defaults in `limits` in the config file: retries per action, actions per turn, and time per turn. When the loop hits a limit, it logs a warning and ends the turn. Commit: `feat(core): add turn limits`.

## Done when

In a running game with the actions per turn limit set to 1, the agent's turn ends after one action, and the log shows a warning that names the limit.

## Record

- The limits and their defaults, in [turn-loop.md](../../design/agents/turn-loop.md#failure-handling).
