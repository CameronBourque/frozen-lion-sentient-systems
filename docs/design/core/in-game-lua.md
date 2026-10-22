# Core mod

The core mod is core's in-game Lua. It signals turns, builds each player's view of the game, runs actions through the game's own request functions, and answers Civilopedia lookups. [findings/lua-contexts.md](../../findings/lua-contexts.md) tracks which Lua state each part runs in.

- **Tagged lines.** Every line the bridge must read has the form `[SENTIENTSYSTEMS] <KIND> <args>`, joined with spaces. `SentientSystems_Print` in `Scripts/SentientSystemsCore_Tag.lua` prints them. The tuner adds the state's name in front, so the bridge receives lines such as `SentientSystemsCore_UI: [SENTIENTSYSTEMS] AGENT_TURN 0`. See [findings/tuner-protocol.md](../../findings/tuner-protocol.md#what-we-know-now).
- **Turn events.** The UI script listens for `Events.PlayerTurnActivated` and prints `AGENT_TURN <playerID>` when a human player's turn starts. The tuner connection carries that line to the bridge.
- **Load line.** Each time the UI script loads, including after a live reload, it prints `CORE_LOADED <state>`, with the state name from `ContextPtr:GetID()`. The bridge logs it, which marks where the core mod started in the log.
- **Version report.** `SentientSystems_GetVersion()` in the UI script reads `<Properties><Version>` from the mod's `.modinfo` and prints `CORE_VERSION <version>`. See [versioning.md](../versioning.md#release-flow).
- **State serializer.** It builds a view of one player's game from that player's own visibility data, never from what is on screen. A map-reveal toggle can then never leak hidden information to an agent. The view includes:
  - cities, units, visible tiles, and what blocks the end of the turn,
  - the scoreboard and victory progress that a human player can see,
  - for each discrete choice, the legal options with turns to complete, boost status or the boost requirement, resource requirements, and prerequisites.
- **Action API.** Each action wraps the request function the game's own UI calls, and the game checks legality. A failed action returns its reason. The reason comes from the game's check where it gives one, and from the API's own messages for common cases. The game's UI Lua files ship as plain text and show which call each screen makes. See [findings/game-api.md](../../findings/game-api.md).
- **Checkpoint ID.** A gameplay script writes the checkpoint ID described in [memory.md](../memory.md#checkpoint-ids).
- **Civilopedia lookup.** It queries the `GameInfo` tables and localized text at runtime, so DLC and other mods are included. It also reads the Civilopedia's Concepts section for general rules such as movement, combat, and terrain.

## Decisions

| Decision | Reason |
| --- | --- |
| State comes from the player's visibility data, not the screen | A map reveal can never leak to an agent |
| The state lists legal options for discrete choices | Saves wasted calls. Spatial actions return failure reasons instead |
| Every failed action returns a reason | The agent can decide again instead of repeating a mistake |
| The state includes the scoreboard and victory progress | A human sees it, and sweat levels measure against it |
| Find the state size by measurement | No useful budget exists before the first full game |
| Game facts come from the Civilopedia at runtime | It includes DLC and mods with no upkeep |
| Lines for the bridge start with `[SENTIENTSYSTEMS]` | The tuner carries every print from every state, including the game's and other mods'. The tag lets the bridge pick out its own lines, and another mod's `AGENT_TURN` print can't start an agent turn |
| The turn signal comes from the UI state | The gameplay and UI events both fire once per human turn. The bridge already calls the UI state for the version report and for actions |
| Each mod file name starts with the mod's prefix, such as `SentientSystemsCore_` | `include` finds a file by name among every enabled mod's imported files, so a generic name can load another mod's file |
| The core mod has no gameplay script until checkpoint IDs need one | Nothing else needs a gameplay state yet |
