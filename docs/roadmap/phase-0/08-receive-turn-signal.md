# Step 8: Receive the turn signal

Turn the core mod's [tagged lines](../../design/core/in-game-lua.md) into typed events in the bridge. Part of [phase 0](README.md).

## Tasks

1. Add `src/log.ts`, which prints each line with the time in front. Make `scripts/watch-states.ts` use it.
2. Add `src/events.ts` to parse tagged lines into typed events: `{ type: "turn", playerId }` and `{ type: "version", version }`. The line format is in [in-game-lua.md](../../design/core/in-game-lua.md). Ignore lines without the tag.
3. Strip the state name from the client's `output` lines before parsing. A version line arrives differently. It comes back without a state name in the lines of a `run()` call to `SentientSystems_GetVersion()`, and [step 9](09-resync-on-connect.md) makes that call.
4. In `src/main.ts`, connect the tuner client, parse each `output` line, and log each event. Log a warning for a tagged line that doesn't parse.
5. To test, end a turn. Check that the log shows `turn 0` when your turn starts.

## Done when

Ending a turn in the game makes the bridge log `turn 0` within about a second.

## Record

- How long the turn signal takes to reach the bridge, in [tuner-commands.md](../../findings/tuner-commands.md#behavior-notes).
- What `src/log.ts` and `src/events.ts` do, in [bridge.md](../../design/core/bridge.md).
