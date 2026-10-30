# Testing

Tests use fixed presets with a fixed map seed, so a rerun shows whether a change helped or the agent got lucky. Playtests judge fun and advice quality.

## Presets

| Preset | Map | Players | Speed and difficulty | Other settings |
| --- | --- | --- | --- | --- |
| Smoke test | Duel, Pangaea | One agent, one AI | Online, Settler or Chieftain | Barbarians off, 0 city-states, disaster intensity 0 |
| MVP gate | Tiny, Pangaea | One agent, three AIs, a few city-states | Online, Prince | Barbarians on, all victory types, Gathering Storm rules, no optional game modes, autosave every turn |

## Test matrix

After phase 1, a test matrix changes one setting at a time: map size, player count, ruleset, optional game modes, and game mode.

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
| Playtests judge fun and advice quality | These two checks cannot be automated |
| Phase 1 sends the full state, measures it, and then trims it | The state size per turn is unknown until it is measured |
