# Step 3: Logs and errors

Add the three log levels and one log file per game. Wrap the core mod's event handlers in `pcall`, so a Lua error reaches the bridge as a tagged `ERROR` line. Part of [phase 1](README.md).

## Tasks

1. **Levels.** In `src/log.ts`, add the three levels from [bridge.md](../../design/core/bridge.md): off, decisions only, and full. Add a `decision(...)` call for lines that every level but off writes, and a `full(...)` call for prompts and responses. Warnings and errors print at every level. Read the level from the config file. Commit: `feat(core): add log levels`.
2. **Log file.** Write each game's log lines to `logs/<date>-<time>.log` next to the config file. Start a new file when a game loads. Until step 4, a new connection counts as a new game. Commit: `feat(core): write a log file per game`.
3. **`pcall` in the core mod.** Wrap each event handler in `SentientSystemsCore_UI.lua` with a helper in `SentientSystemsCore_Tag.lua`. On an error, the helper prints `ERROR <handler> <message>`. Commit: `feat(core): catch errors in core mod event handlers`.
4. **`ERROR` in the bridge.** In `src/events.ts`, parse `ERROR` with the handler as one word and the rest of the line as the message, and log it as an error. Test a message that holds spaces. Commit: `feat(core): log ERROR lines from the core mod`.
5. **Docs.** Describe the `ERROR` line in [in-game-lua.md](../../design/core/in-game-lua.md) and the log file in [bridge.md](../../design/core/bridge.md). Commit: `docs: describe ERROR lines and log files`.

## Done when

All of these hold in a running game:

- With a temporary `error("test")` in the turn handler, the bridge logs `ERROR` with the handler's name, and the game keeps running.
- With the level set to off, the log file holds only warnings and errors.
- Each load of a save starts a new log file.

## Record

- The `ERROR` line and the `pcall` helper, in [in-game-lua.md](../../design/core/in-game-lua.md).
- The levels and the log file, in [bridge.md](../../design/core/bridge.md).
