# Step 3: Logs and errors

Replace the bridge's text log with structured logs at five levels, written to the console and to one log file per game. Wrap the core mod's event handlers, so a Lua error reaches the bridge as a tagged `ERROR` line. Part of [phase 1](README.md).

## Tasks

1. **Plan.** Rewrite this step file for structured logs, and add the log filter to the [phase 2](../phase-2/README.md) scope. Commit: `docs: plan structured logs for step 3`.
2. **Logger.** In `src/log.ts`, replace `log` and `warn` with a `Logger` class. It has one method for each level, from quietest to noisiest: `error`, `warn`, `info`, `decision`, and `debug`. Each call takes an event name, a message, and optional fields, such as `logger.info("turn", "Player 0's turn started", { playerId: 0 })`. Each call builds a record with `time`, `level`, `event`, `msg`, and the fields. The console prints the local time and `msg`, with `warning: ` or `error: ` in front of warnings and errors. Commit: `feat(core): add the structured logger`.
	- In `src/config.ts` and the example config, set the `logLevel` options to the five levels, with `decisions` as the default. A level writes its own records and the records of every quieter level. The schema hasn't been released, so `schemaVersion` stays at 1.
	- Create the logger in `src/main.ts`, and pass it to `src/connect.ts` and `src/events.ts`. Until the config file loads, the logger writes at the default level.
	- Give each kind of line a fixed event name, such as `connected`, `core_version`, `core_loaded`, `turn`, and `bad_line`. Make each message read on its own, such as `Player 0's turn started` in place of `turn 0`.
3. **Log file.** Write each record as one JSON line to `logs/<timestamp>.log` in the config file's folder, such as `logs/2026-10-23-181911.log`. Commit: `feat(core): write a log file per game`.
	- Open the first file when the bridge starts, so the startup lines are in it.
	- Start a new file on each connect after the first. Until step 4, a new connection counts as a new game.
	- If the folder or the file can't be written, warn on the console and keep logging to the console only.
4. **Lua error helper.** In `SentientSystemsCore_Tag.lua`, add a helper that takes a handler's name and function, and returns the function wrapped in `xpcall` with `debug.traceback`. Commit: `feat(core): catch errors in core mod event handlers`.
	- If `debug` is missing, the helper uses `pcall` with no traceback.
	- On an error, the helper prints `ERROR <handler> <message>`. It escapes each backslash as `\\` and each newline as `\n`, so the tuner sends the error as one line.
	- Wrap each event handler in `SentientSystemsCore_UI.lua` with the helper.
5. **`ERROR` in the bridge.** In `src/events.ts`, parse `ERROR` with the handler as one word and the rest of the line as the message. Commit: `feat(core): log ERROR lines from the core mod`.
	- Undo the escapes, then split the text at the `stack traceback:` line into `message` and `traceback`.
	- Log an error with the event `core_error` and the fields `handler`, `message`, and `traceback` when there is one.
	- Test a message with spaces, a message with an escaped newline, and a message with a traceback.
6. **Docs.** Describe the logger, the levels, and the log file in [bridge.md](../../design/core/bridge.md). Describe the `ERROR` line and the helper in [in-game-lua.md](../../design/core/in-game-lua.md). Commit: `docs: describe structured logs and ERROR lines`.

## Done when

All of these hold in a running game:

- With a temporary `error("test")` in the turn handler, the bridge logs a `core_error` record with the handler's name, and the game keeps running. The record has a traceback if `debug.traceback` works in the core mod's UI state.
- With `logLevel: warn`, the console and the log file hold only warnings and errors.
- Each line on the console is also a record in the log file.
- Each load of a save starts a new log file.

## Record

- The logger, the levels, and the log file, in [bridge.md](../../design/core/bridge.md).
- The `ERROR` line and the helper, in [in-game-lua.md](../../design/core/in-game-lua.md).
- Whether `debug.traceback` works in a UI state, in [lua-contexts.md](../../findings/lua-contexts.md).
