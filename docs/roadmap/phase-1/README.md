# Phase 1: MVP, one agent finishes a game

The minimum viable product is the full agent loop playing a whole single-player game. Every later phase builds on it.

**Gate.** One agent plays a full single-player game against the native AI with no manual help.

## Scope

- Model client behind one provider interface
- State serializer for one player, with the scoreboard and option details, filtered by that player's visibility
- Action API with failure reasons, for units, city production, techs, civics, policies, and end turn
- End-turn blocker loop with retry, action, and time limits
- MCP server and agent loop
- Generated tool reference, and the workflow that updates it. See [bridge.md](../../design/core/bridge.md)
- Plain-code handling for idle units and scouts
- Required `reason` field on every action
- Logs with the three log levels
- Decision records
- Plan and journal memory, with no snapshots yet
- One default personality and the balanced sweat level
- Civilopedia `lookup` tool
- A config file marks the agent slot. No setup screen changes yet
- Pass the smoke test preset, then the MVP gate preset
- Measure the state size and the cost of one full game

Design: [core/](../../design/core/README.md), [agents/turn-loop.md](../../design/agents/turn-loop.md), [memory.md](../../design/memory.md), [testing.md](../../design/testing.md).

## Steps

Not broken down yet. When it is, the scope items become steps, and we remove this list.
