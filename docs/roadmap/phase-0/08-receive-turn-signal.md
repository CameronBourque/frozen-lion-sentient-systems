# Step 8: Receive the turn signal

Turn the tagged lines from [step 7](07-minimal-core-mod.md) into typed events in the bridge. Part of [phase 0](README.md).

## Tasks

1. Add `src/events.ts` to parse tagged lines from the tuner output stream into typed events: `{ type: "turn", playerId }` and `{ type: "version", version }`.
2. Log each event with a timestamp.
3. To test, end a turn. Check that the log shows `turn 0` when your turn starts.
4. Check whether AI turns also print. If they do, adjust the filter.

## Done when

Ending a turn in the game makes the bridge log `turn 0` within about a second.

## Record

Whether AI turns print the turn signal, in [tuner-commands.md](../../findings/tuner-commands.md#behavior-notes).
