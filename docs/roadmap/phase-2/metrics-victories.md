# Era and victory metrics

Add each player's era and its progress toward each victory to the [metrics line](metrics-line.md). The design is in [evaluation.md](../../design/evaluation.md#metrics-line). Part of [phase 2](README.md).

## Tasks

1. **Era.** Add the era, the era score, and the age the player is in: dark, normal, golden, or heroic. Grow the schema and the fixture with them. Commit: `feat(core): add the era to the metrics`.
2. **Victory progress.** Add progress toward each victory, from the same calls as the [victories](../../findings/state/victories.md) section of the state, for every major player. Grow the schema and the fixture with it. Commit: `feat(core): add victory progress to the metrics`.

## Done when

After an agent turn in a running game, the agent's era and age match the **Era** screen, its victory progress matches the victories section of its state, and every major player has each field.

## Record

- Any field that the game can't give, and the calls that give the rest, in [evaluation.md](../../design/evaluation.md#metrics-line).
