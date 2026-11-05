# Testing

Tests use fixed presets with a fixed map seed, so a rerun shows whether a change helped or the agent got lucky. Scenario tests check one hard moment from a save. Playtests judge fun and advice quality.

## Presets

| Preset | Map | Players | Speed and difficulty | Other settings |
| --- | --- | --- | --- | --- |
| Smoke test | Duel, Pangaea | One agent, one AI | Online, Settler or Chieftain | Barbarians off, 0 city-states, disaster intensity 0 |
| MVP gate | Tiny, Pangaea | One agent, three AIs, a few city-states | Online, Prince | Barbarians on, all victory types, Gathering Storm rules, no optional game modes, autosave every turn |

## Test matrix

After phase 1, a test matrix changes one setting at a time: map size, player count, ruleset, optional game modes, and game mode.

## Scenario tests

A scenario test loads a save set at one hard moment, lets the agent play a few turns, and checks an outcome with code. A full game takes hours and mixes every decision together. A scenario takes a few turns and tests one decision, so it shows whether a change to a prompt, a guide, a [decision helper](decision-support/helpers.md), or a [model tier](decision-support/model-routing.md#tiers) helped.

A scenario has these parts:

- a save,
- the agent's personality and sweat level,
- the number of turns to play,
- a check that code runs on the state after the last turn.

The check judges the outcome, never the moves. Grading each move takes a person and a long time, and two people grade moves differently. An outcome, such as a city that still stands, needs no judgment.

These are the first scenarios. The list is partial.

| Scenario | Save | Passes when |
| --- | --- | --- |
| Defend a city | Three enemy units next to a city with one defender | The city still belongs to the agent after 10 turns |
| Surprise war | A neighbor declares war with its army near the border | Within 2 turns, the agent has units in each threatened city |
| Pick a settle site | A settler with several sites in reach | The settler founds a city within 5 turns |
| Recover the treasury | Gold income below 0 | Gold income is above 0 within 5 turns |

A model does not give the same answer each time. Each scenario runs several times, and the result is a pass rate.

We keep only a few scenarios. Each one needs a save, and a save made for one version of the game or the core mod can break on the next. The [game review](decision-support/game-review.md#steps) turning points show which moments are worth a scenario. A save can also be set up with the tuner, such as by placing enemy units next to a city.

Scenarios run on demand, not in CI, because they need the game and cost model calls.

## Playtests

Two checks cannot be automated. Agent players must be more fun to play against than the native AI. Advisors must give advice that a player can follow and then judge as good or bad. Playtests with short notes after each game answer both.

## State size

Measurement sets the state size per turn. Phase 1 sends the full state, measures it, and trims. See the [risk](../risks.md).

`npm run state` prints the size in bytes of the state, the choices, and each tree, and under the state and the choices, the size and share of each section, largest first. A section's size is its compact JSON. The sections add up to a little less than the total, which includes the braces and keys around them. The sizes are in bytes, not tokens.

### Sizes on turns 24 and 403

Each part's size in bytes for the local player, in a single-player game with Gathering Storm on a Huge map (106 by 66 tiles), measured on 2026-10-29. The turn 24 save has 19 major players, 10 of them known to the player. The turn 403 save is the late game. The map is the largest the game has, so the tiles are as big as they get. A smaller map has fewer tiles.

| Part | Turn 24 | Turn 403 |
| --- | --- | --- |
| State | 247,075 | 282,928 |
| `tiles` | 154,859 (63%) | 178,084 (63%) |
| `player` | 24,248 (10%) | 30,191 (11%) |
| `victories` | 16,682 (7%) | 17,408 (6%) |
| `greatPeople` | 10,746 (4%) | 10,664 (4%) |
| `cities` | 9,632 (4%) | 12,748 (5%) |
| `scoreboard` | 8,957 (4%) | 8,557 (3%) |
| `diplomacy` | 7,623 (3%) | 8,320 (3%) |
| `envoys` | 6,645 (3%) | 5,755 (2%) |
| `units` | 3,506 (1%) | 5,408 (2%) |
| `rivals` | 2,738 (1%) | 3,602 (1%) |
| `governors`, `religion`, `blockers`, and `proposals` | 1,180 | 1,922 |
| Choices | 71,180 | 123,742 |
| `production` | 43,671 (61%) | 84,056 (68%) |
| `purchases` | 14,700 (21%) | 17,994 (15%) |
| `governments` | 4,673 (7%) | 4,360 (4%) |
| `policies` | 3,536 (5%) | 11,360 (9%) |
| `techs`, `civics`, `governors`, `government`, `capturedCities`, and `envoys` | 4,331 | 5,561 |
| Tech tree | 21,118 | 21,189 |
| Civic tree | 19,017 | 16,658 |

The tiles are the largest part of the state, at about two thirds on both turns, and the production options the largest of the choices. The state grows by about a seventh over 380 turns, and the choices by about three quarters, mostly in production and policies.

## Decisions

| Decision | Reason |
| --- | --- |
| Tests use fixed presets with a fixed map seed | A rerun shows whether a change helped or the agent got lucky |
| The test matrix starts after phase 1 and changes one setting at a time | A failure points at the one setting that changed |
| Scenario tests check an outcome with code, never the moves | Grading moves takes a person, and two people grade them differently |
| Each scenario runs several times and reports a pass rate | A model does not give the same answer each time |
| Only a few scenarios, run on demand | Each save needs upkeep, and each run needs the game and costs model calls |
| Playtests judge fun and advice quality | These two checks cannot be automated |
| Phase 1 sends the full state, measures it, and then trims it | The state size per turn is unknown until it is measured |
