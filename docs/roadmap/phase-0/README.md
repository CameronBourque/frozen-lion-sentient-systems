# Phase 0: Prove the bridge

Every later phase depends on the FireTuner channel, and its protocol is undocumented, so phase 0 proves it first.

**Gate.** From the bridge, list your cities and move one unit.

The gate passed on 2026-10-23, and the phase is done.

## What it proved

- The bridge connects to the game's tuner, runs Lua in a chosen state, and reads what it prints. The tuner needs no SDK on Windows.
- The core mod's turn signal reaches the bridge within about a second, and the bridge recovers the turn state when it restarts.
- Actions requested from the core mod's UI state take effect, so the action API can run there.
- The released executable runs on a clean Windows with no Node, and passes the same turn signal and restart checks.
- The game closes the tuner port in hotseat and in online games, so the bridge works in single player only.

The results are in [done.md](done.md).
