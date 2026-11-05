# Core mod lines

The lines the core mod prints for the bridge: turn signals, load lines, the version report, and errors. Part of the [core mod](README.md).

## Tagged lines

Every line the bridge must read has the form `[SENTIENTSYSTEMS] <KIND> <args>`, joined with spaces. `SentientSystems_Print` in `Scripts/SentientSystemsCore_Common.lua` prints them.

The tuner adds the state's name in front, so the bridge receives lines such as `SentientSystemsCore_UI: [SENTIENTSYSTEMS] AGENT_TURN 0`. See [findings/tuner/protocol.md](../../../findings/tuner/protocol.md#what-we-know-now).

## Turn events

The UI script listens for `Events.PlayerTurnActivated` and prints `AGENT_TURN <playerID>` when an agent player's turn starts. The tuner connection carries that line to the bridge.

One function, `IsAgentPlayer`, decides which players are agent players. For now it picks the human players. When agents can play any slot, only that function changes.

## Resync

`SentientSystems_Resync()` in the UI script prints `AGENT_TURN <playerID>` for each living agent player whose turn is active, the same line the turn event prints. Between turns it prints nothing.

The bridge calls it when it connects, so a restart in the middle of a turn doesn't miss the turn.

## Load line

Each time the UI script loads, including after a live reload, it prints `CORE_LOADED <state>`, with the state name from `ContextPtr:GetID()`. The bridge logs it, which marks where the core mod started in the log.

## Load signal

The UI script prints two lines during a load:

- **`LOAD_READY`.** `Events.LoadGameViewStateDone` prints it when the loading screen shows its button. The tuner carries the line, but runs no commands until the click.
- **`GAME_READY <turn>`.** `Events.LoadScreenClose` prints it, with the turn from `Game.GetCurrentGameTurn()`, when the button is clicked, by the player or by the game. Commands work from then on.

The socket resets right after the click, and the `GAME_READY` line reaches the bridge first. In hotseat and other games where the game clicks the button, the two lines come one right after the other. See [findings/lua/state-list.md](../../../findings/lua/state-list.md#state-list-over-a-session).

## Errors

### Event handlers

`SentientSystems_CatchErrors(name, handler)` in `Scripts/SentientSystemsCore_Common.lua` returns the handler wrapped in `pcall`. Each event handler is added through it, such as `Events.PlayerTurnActivated.Add(SentientSystems_CatchErrors("OnPlayerTurnActivated", OnPlayerTurnActivated))`.

When the handler raises a Lua error, the helper prints `ERROR <handler> <message>` in its place. The functions the bridge calls, such as `SentientSystems_Resync()`, aren't wrapped, because the tuner already returns their errors to the call.

The game's Lua puts the stack trace in the error message, so the line carries the trace without the `debug` library, which UI states don't have. See [findings/lua/dialect.md](../../../findings/lua/dialect.md#what-we-know-now).

The helper escapes each backslash as `\\`, each newline as `\n`, and each percent sign as `\p`. The whole error then arrives as one line, and the game's log doesn't read a `%` as a printf format code.

### Missing files

`SentientSystems_Include(name)` in the same file loads a file as `include` does. The scripts load every core mod file through it, except `SentientSystemsCore_Common`, which defines it.

When the game knows no file by that name, `include` returns an empty list and raises no error. The helper prints `ERROR include found no file named <name>` instead.

That happens when a file is added to the `.modinfo` and the game isn't restarted. See [findings/lua/contexts.md](../../../findings/lua/contexts.md#the-core-mods-states).

## Version report

`SentientSystems_GetVersion()` in the UI script reads `<Properties><Version>` from the mod's `.modinfo` and prints `CORE_VERSION <version>`. See [versioning.md](../../versioning.md#release-flow).

## Decisions

| Decision | Reason |
| --- | --- |
| Lines for the bridge start with `[SENTIENTSYSTEMS]` | The tuner carries every print from every state, including the game's and other mods'. The tag lets the bridge pick out its own lines, and another mod's `AGENT_TURN` print can't start an agent turn |
| A file that `include` can't find prints an `ERROR` line | `include` returns an empty list with no error. The first sign would come later, as a call to a `nil` function, with nothing to say which file is missing |
| Event handlers report Lua errors as tagged `ERROR` lines | An uncaught error reaches the bridge only as an untagged game line, which it ignores. The bridge would wait for a turn signal that never comes, and nothing would say why |
| The error helper uses `pcall`, not `xpcall` with `debug.traceback` | The error message already holds the stack trace, and UI states have no `debug` library. `pcall` also passes the handler's arguments, so the helper needs no closure |
| The error helper escapes newlines and backslashes | The tuner sends each line of a print as its own line, and only the first one has the state's name. Without the escapes, the trace would arrive as untagged lines |
| The turn signal comes from the UI state | The gameplay and UI events both fire once per human turn. The bridge already calls the UI state for the version report and for actions |
| The load signal is two tagged lines from the loading screen's events | The bridge reads only tagged lines. `LOAD_READY` comes before the click, so the new log file and a later tool's click start there. `GAME_READY` arrives before the socket resets, so it needs no resync |
