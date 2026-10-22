# Step 8: Receive the turn signal

Turn the core mod's [tagged lines](../../design/core/in-game-lua.md) into typed events in the bridge. Part of [phase 0](README.md).

## Tasks

1. Add `src/events.ts` to parse tagged lines from the tuner output stream into typed events: `{ type: "turn", playerId }` and `{ type: "version", version }`. The line format is in [in-game-lua.md](../../design/core/in-game-lua.md). Strip the state name the tuner adds, and ignore lines without the tag.
2. Log each event with a timestamp.
3. To test, end a turn. Check that the log shows `turn 0` when your turn starts.

## Done when

Ending a turn in the game makes the bridge log `turn 0` within about a second.

## Record

How long the turn signal takes to reach the bridge, in [tuner-commands.md](../../findings/tuner-commands.md#behavior-notes).
