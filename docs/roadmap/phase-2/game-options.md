# Game options

Warn when a game option that slows the agent's turns is off. The design is in [turn-loop.md](../../design/agents/turn-loop.md). Part of [phase 2](README.md).

## Tasks

1. **Quick movement and combat.** Check that quick movement and quick combat are on when an agent turn starts, and log a warning when one is off. Commit: `feat(core): warn when quick movement or quick combat is off`.

## Done when

In a running game with quick combat off, the log shows the warning when the agent's turn starts.

## Record

- The options the loop checks, in [turn-loop.md](../../design/agents/turn-loop.md).
