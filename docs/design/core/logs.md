# Logs

How the bridge logs: one record for each line, five levels, the home folder hidden, and one JSON log file for each game. Part of the [bridge](bridge.md).

`src/main.ts` creates one `Logger`, from `src/log.ts`, and passes it to the code that logs. Each call builds a log record with `time`, `level`, `event`, `msg`, and any fields, such as `{ "level": "info", "event": "turn", "msg": "Player 0's turn started", "playerId": 0 }`. `time` is UTC in ISO 8601 form. `event` is a fixed name for each kind of line, such as `connected`, `core_version`, `turn`, `bad_line`, or `core_error`, so a filter matches the name and not the message. The console prints the local time and `msg`, with `warning: ` or `error: ` in front, and sends warnings and errors to stderr.

- **Levels.** From quietest to noisiest, the levels are `error`, `warn`, `info`, `decisions`, and `debug`. `logLevel` in the config file names the noisiest level the logger writes, to the console and to the file alike. `decisions` holds each agent action and its reason, and `debug` adds each prompt and response. Until the config file loads, the logger writes at `decisions`.
- **Home folder.** Before it writes a record, the logger replaces the user's home folder with `~` in `msg` and in every string field, such as `~\OneDrive\Documents\sentient-systems.yaml`. The match ignores case, and it only matches a whole folder name.
- **Log files.** The logger writes each record as one JSON line to `logs/<date>-<time>.log` in the config file's folder, such as `logs/2026-10-23-181911.log`, named by local time. The first file opens when the config file loads, so it holds the startup lines. A load resets the socket, so each connect after the first starts a new file, until the [load signal](../../roadmap/phase-1/04-load-signal.md) replaces that rule. A config file that fails to load has no folder for logs, so its error goes to the console only. Each write is synchronous. If the folder or the file can't be written, the logger warns once and logs to the console only.

## Decisions

| Decision | Reason |
| --- | --- |
| Structured log records, each with a fixed event name | A filter, such as the `logs` command planned for [phase 2](../../roadmap/phase-2/README.md#scope), reads fields instead of matching message text. The console still shows one plain line per record |
| Five levels, with `decisions` between `info` and `debug`, and `decisions` as the default | Prompts and responses make `debug` logs large. `decisions` shows each agent's actions and reasons without them, and those reasons are what a player watches for |
| A small logger class of our own, with no logging library | The bridge needs one console format and one file. pino sends output through worker threads, which a single executable has to bundle |
| One JSON line per record, and one file per game | A JSON line appends without rewriting the file, and `ConvertFrom-Json` in PowerShell or `jq` reads it. One file per game keeps each game's log in one place |
| Synchronous writes to the log file | Records stay in order, and none is lost when the bridge exits right after an error. A write takes microseconds, next to model calls that take seconds. A worker thread would need a flush before exit |
| A log file that can't be written warns, and the bridge keeps logging to the console | The bridge plays without its log file, so a full disk or a locked folder shouldn't stop a game |
| The logger replaces the home folder with `~` in every record | Players share logs in bug reports, and a path under the home folder holds the user's name. The logger covers every path, including ones that later code logs |
