# Phase 1: Agent tools over MCP

Core reads the game, runs every action a player can take, and serves both as MCP tools. An outside MCP client, such as Claude Code, can then play the game, with you prompting each turn. The [agent loop](../phase-2/README.md) in phase 2 calls the same tools.

**Gate.** From Claude Code, play 10 turns of a single-player game through the MCP server, with a `reason` on every action.

The gate passed on 2026-11-19, and the phase is done. It made no release of its own: core and the agent players mod release together when phase 2 closes.

## What it proved

- The core mod reads one player's game from that player's own visibility data: the map, cities, units, rivals, diplomacy, religion, great people and works, trade, espionage, the scoreboard, victory progress, the events its popups would show, and the current turn.
- It lists the legal options for every decision, and runs every action a player can take from its UI state. Each failed action returns a reason, from the game where it gives one and from the core mod where it doesn't.
- It closes the popups that wait for a click for an agent player, and answers the leader screens that need no decision.
- The bridge serves the state, the choices, the actions, and a Civilopedia lookup as 44 MCP tools over local HTTP, with a required `reason` on every action and a generated tool reference.
- Claude Code played 10 turns of the smoke test preset through those tools, with only a prompt at the start of each turn, a `reason` on every action, and no `ERROR` lines. The runs are in [findings/agent-runs.md](../../findings/agent-runs.md).
- When a queued move stops short, the game cancels the end of the turn and starts it again. The core mod prints `AGENT_TURN` with `again`, but a model that isn't told can't see it, so the phase 2 loop tells it.

The results are in [done/](done/README.md).
