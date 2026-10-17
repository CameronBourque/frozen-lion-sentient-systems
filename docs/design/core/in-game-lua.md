# Core mod

The core mod is core's in-game Lua. It signals turns, builds each player's view of the game, runs actions through the game's own request functions, and answers Civilopedia lookups. [findings/lua-contexts.md](../../findings/lua-contexts.md) tracks which Lua state each part runs in.

- **Turn events.** The mod listens for the game's turn-start events and prints tagged lines such as `AGENT_TURN 3`. The tuner connection carries that output to the bridge.
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
