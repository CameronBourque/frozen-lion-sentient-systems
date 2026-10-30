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

### Sizes on turn 403

A single-player game with Gathering Storm, on turn 403 with 20 players, 14 of them met, for the local player, measured on 2026-10-29. The late game is the largest case, since the revealed tiles, the cities, and the victories grow with the game. An early turn is to be added.

| Part | Bytes | Share of its total |
| --- | --- | --- |
| State | 282,928 | |
| `tiles` | 178,084 | 63% |
| `player` | 30,191 | 11% |
| `victories` | 17,408 | 6% |
| `cities` | 12,748 | 5% |
| `greatPeople` | 10,664 | 4% |
| `scoreboard` | 8,557 | 3% |
| `diplomacy` | 8,320 | 3% |
| `envoys` | 5,755 | 2% |
| `units` | 5,408 | 2% |
| `rivals` | 3,602 | 1% |
| `governors`, `religion`, `blockers`, and `proposals` | 1,922 | under 1% each |
| Choices | 123,742 | |
| `production` | 84,056 | 68% |
| `purchases` | 17,994 | 15% |
| `policies` | 11,360 | 9% |
| `governments` | 4,360 | 4% |
| `governors` | 3,896 | 3% |
| `techs`, `civics`, `government`, and `envoys` | 1,665 | 1% or less each |
| Tech tree | 21,189 | |
| Civic tree | 16,658 | |

The tiles are the largest part of the state, and the production options the largest of the choices.

## Decisions

| Decision | Reason |
| --- | --- |
| Tests use fixed presets with a fixed map seed | A rerun shows whether a change helped or the agent got lucky |
| The test matrix starts after phase 1 and changes one setting at a time | A failure points at the one setting that changed |
| Playtests judge fun and advice quality | These two checks cannot be automated |
| Phase 1 sends the full state, measures it, and then trims it | The state size per turn is unknown until it is measured |
