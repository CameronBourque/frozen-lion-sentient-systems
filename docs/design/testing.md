# Testing

Tests use fixed presets with a fixed map seed, so a rerun shows whether a change helped or the agent got lucky. Playtests judge fun and advice quality.

## Presets

| Preset | Map | Players | Speed and difficulty | Other settings |
| --- | --- | --- | --- | --- |
| Smoke test | Tiny, Pangaea | One agent, one AI | Online, Settler or Chieftain | Barbarians off |
| MVP gate | Small, Pangaea | One agent, two or three AIs, a few city-states | Online, Prince | Barbarians on, all victory types, Gathering Storm rules, no optional game modes, autosave every turn |

## Test matrix

After phase 1, a test matrix changes one setting at a time: map size, player count, ruleset, optional game modes, and single player against hotseat.

## Playtests

Two checks cannot be automated. Agent players must be more fun to play against than the native AI. Advisors must give advice that a player can follow and then judge as good or bad. Playtests with short notes after each game answer both.

## State size

Measurement sets the state size per turn. Phase 1 sends the full state, measures it, and trims. See the [risk](../risks.md).

## Decisions

| Decision | Reason |
| --- | --- |
| Tests use fixed presets with a fixed map seed | A rerun shows whether a change helped or the agent got lucky |
| The test matrix starts after phase 1 and changes one setting at a time | A failure points at the one setting that changed |
| Playtests judge fun and advice quality | These two checks cannot be automated |
| Phase 1 sends the full state, measures it, and then trims it | The state size per turn is unknown until it is measured |
