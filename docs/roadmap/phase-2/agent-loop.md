# Agent loop

Run an agent's turn when its turn signal arrives: read the state, give the model the MCP tools, and pass its tool calls to the MCP server until it calls `end_turn`. The design is in [turn-loop.md](../../design/agents/turn-loop.md). Part of [phase 2](README.md).

## Tasks

1. **MCP tools.** Connect the loop to the MCP server in the same process, and turn the server's tools into the [model client](../../design/core/model-client.md)'s tool definitions, with each tool's description and input schema. Test it with a fake client. Commit: `feat(core): give the model the MCP tools`.
2. **Turn.** Add `src/agents/loop.ts`. It reads the state and the agent's memory, builds the prompt, and passes the model's tool calls to the MCP server and their results back to the model, until the model calls `end_turn`.

   On the agent's first turn after the bridge starts, read the memory with `startMemory`, so [stale memory](../../design/memory.md#stale-memory) moves aside. On later turns, read it with `readMemory`. Log each warning that either returns. Test it with a mock model and a fake client. Commit: `feat(core): run an agent's turn`.
3. **Turn signal.** On `AGENT_TURN`, start that player's agent turn, and build its agent the first time. The core mod prints the line only for agent players, so the bridge keeps no list of agents.

   In a run mode the model client can't call, warn once and play no turns. Commit: `feat(core): start an agent's turn on its turn signal`.

## Done when

In a running game, the bridge executable plays one agent turn with no manual help, and the log shows each tool call with its `reason`. The executable runs with no `knowledge` folder next to it, and its prompt holds the personality, the sweat level, and the state.

## Record

- The loop, in [turn-loop.md](../../design/agents/turn-loop.md).
