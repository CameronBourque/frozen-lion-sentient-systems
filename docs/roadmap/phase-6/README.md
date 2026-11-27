# Phase 6: Setup screen, spectating, and release

This phase makes the mods usable by a nontechnical user and ships the first release. It adds setup screen options, spectator mode, the launcher, first-run setup, and self-update.

**Gate.** A nontechnical user installs the mods and the bridge, sets them up, and watches an agent-only game without editing a file.

## Scope

- **Agent** option in the player-type dropdown
- Personality and sweat level dropdowns per slot
- Spectator mode setup option, pacing, and camera, including the camera moves that closed popups still start, such as the jump to a natural wonder and its fly-around, and the timeline, great work gallery, and leader screens, which the core mod closes when a spectator opens them in an agent's game
- Map reveal toggle, rendering only. Test the observer view in question 1 of [state/tile-visibility.md](../../findings/state/tile-visibility.md#questions) first
- Relabel **Difficulty** as **AI Difficulty**
- Launcher shortcut that starts the bridge and the game
- First-run `EnableTuner` setup, with permission
- In-game API key setting
- A stop button and spending limit settings in the game, so a player can [stop an agent](../../design/agents/turn-loop/stopping.md) without leaving the game. Decide whether it is still needed beside the [bridge GUI](../phase-3/README.md)'s stop button.
- Missing-bridge message and bridge self-update
- Bridge release on GitHub and mod upload to the Workshop

Design: [agents/slot-type.md](../../design/agents/slot-type.md), [agents/cover-and-spectator.md](../../design/agents/cover-and-spectator.md), [distribution.md](../../design/distribution.md), [versioning.md](../../design/versioning.md).

## Steps

Not broken down yet. When it is, the scope items become steps, and we remove this list.
