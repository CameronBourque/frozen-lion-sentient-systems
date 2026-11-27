# Idle units and scouts

Handle the units that need no judgment in plain code before the model call, so the model spends its actions on real decisions. The design is in [turn-loop/](../../design/agents/turn-loop/README.md). Part of [phase 2](README.md).

## Tasks

1. **Idle military units.** Before the model call, fortify idle military units that stand in a city or on a fort. Leave other units to the model. Commit: `feat(core): fortify idle units in plain code`.
2. **Scouts.** Before the model call, set idle scouts to auto-explore. Commit: `feat(core): set scouts to auto-explore in plain code`.

## Done when

In a running game, an idle warrior in a city is fortified and an idle scout is exploring before the model's first call of the turn.

## Record

- The plain-code rules, in [turn-loop/](../../design/agents/turn-loop/README.md).
