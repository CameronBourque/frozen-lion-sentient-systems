# Yield and empire metrics

Add each player's yields and the size of its empire to the [metrics line](metrics-line.md). The design is in [evaluation.md](../../design/evaluation.md#metrics-line). Part of [phase 2](README.md).

## Tasks

1. **Yields.** Add science, culture, and faith per turn, gold per turn and the gold balance, production and food per turn summed over the player's cities, and favor and favor per turn with Gathering Storm. Grow the schema and the fixture with them. Commit: `feat(core): add yields to the metrics`.
2. **Empire counts.** Add military strength, the number of cities, the total population, and the number of techs and civics researched. Grow the schema and the fixture with them. Commit: `feat(core): add empire counts to the metrics`.

## Done when

After an agent turn in a running game, the agent's line matches the top bar's yields and the **Reports** screen's city numbers, and every major player has each field.

## Record

- Any field that the game can't give, and the calls that give the rest, in [evaluation.md](../../design/evaluation.md#metrics-line).
