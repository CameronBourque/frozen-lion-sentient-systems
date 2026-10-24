# Glossary

The one name for each thing in this project, and what it means. Use these names in every doc, and add a row here before you introduce a new term. Each row links to the doc that explains the term.

| Term | Meaning | Details |
| --- | --- | --- |
| Action API | The core mod's Lua functions that wrap the game's request functions. A failed action returns a reason | [in-game-lua.md](design/core/in-game-lua.md) |
| Advisors mod | The feature mod that gives a human player read-only advisors, one per victory condition | [advisors.md](design/advisors.md) |
| Agent | An LLM that plays Civ VI as a full player in an **Agent** slot. It is not the native AI | [knowledge-files.md](design/knowledge-files.md#file-layout) |
| **Agent** slot | A player slot that an agent plays. The setup screen shows it as **Agent**. Which engine slot type holds it is open | [slot-type.md](design/agents/slot-type.md) |
| Agent loop | The bridge code that runs an agent's turn. It sends the model a prompt and passes the model's tool calls to the MCP server | [turn-loop.md](design/agents/turn-loop.md) |
| Agent players mod | The feature mod that adds agents, the turn loop, spectator mode, the narrator panel, and messaging | [agents/](design/agents/README.md) |
| Bridge | The external TypeScript program that connects to the tuner, runs the agent loop, and stores agent memory. It ships as one executable, and it is part of core | [bridge.md](design/core/bridge.md) |
| Checkpoint ID | A UUID that a gameplay script writes into the save after each agent turn, so the bridge can restore the matching memory | [memory.md](design/memory.md#checkpoint-ids) |
| Core | The core mod and the bridge together. They are one package, `packages/core`, with one version. Core is the only code that talks to the game | [core/](design/core/README.md) |
| Core API | What core offers the feature mods. Feature mods reach the game only through it | [architecture.md](design/architecture.md#core-boundary) |
| Core mod | The in-game Lua and `.modinfo` in `packages/core/mod`. It does not include the bridge | [in-game-lua.md](design/core/in-game-lua.md) |
| Cover card | The full-screen card that hides the map during agent turns when a human plays | [cover-and-spectator.md](design/agents/cover-and-spectator.md#cover-card) |
| Deep strategic review | A mode of the agent loop that uses a stronger model and compacts the journal | [knowledge-files.md](design/knowledge-files.md#file-layout) |
| Feature mod | The agent players mod or the advisors mod. Each has its own version and a required core range | [versioning.md](design/versioning.md#packages) |
| Finding | A file in `findings/` that records what is true about the game or our tools, with a status of Confirmed or Unconfirmed | [rules/docs.md](rules/docs.md#findings) |
| FireTuner | The SDK's debug program, `FireTuner2.exe`. The FireTuner protocol is the wire protocol it uses | [tuner-protocol.md](findings/tuner-protocol.md) |
| Gate | The test at the end of a phase. It must pass before the next phase starts | [roadmap/](roadmap/README.md) |
| Knowledge files | The concept guides, civ notes, personalities, sweat level files, and model table that teach agents the game | [knowledge-files.md](design/knowledge-files.md) |
| Log record | One entry in the bridge's log: the time, the level, a fixed event name, a message, and any fields. A log file holds one record on each line, as JSON | [bridge.md](design/core/bridge.md) |
| Lua state | One Lua environment in the running game, such as `InGame` or `GameCore_Tuner`. The tuner lists the states and runs Lua in one of them. Use "context" only for the `.modinfo` `Context` attribute | [lua-contexts.md](findings/lua-contexts.md) |
| Marker wrapper | The Lua the tuner client puts around each command. It prints `@@ss:begin:<id>` and `@@ss:end:<id>:<result>`, so the bridge knows which output belongs to which command | [tuner-commands.md](findings/tuner-commands.md#probe-results) |
| MVP | The minimum viable product: one agent finishes a full single-player game against the native AI. It is phase 1 | [phase-1/](roadmap/phase-1/README.md) |
| Native AI | The game's built-in computer players | [slot-type.md](design/agents/slot-type.md) |
| Personality | A file that sets an agent's priorities, behavior rules, and narrator voice | [knowledge-files.md](design/knowledge-files.md#layers) |
| Phase | One stage of the roadmap, with one gate, in `roadmap/phase-N/`. Write "phase 0" in lowercase in running text | [roadmap/](roadmap/README.md) |
| Request function | A game function, such as `UnitManager.RequestOperation`, that asks the engine to do an action. The engine checks that the action is legal | [game-api.md](findings/game-api.md) |
| Single executable application (SEA) | Node's way to build one executable that holds the Node runtime and a bundled program. The bridge ships as one | [build-tooling.md](findings/build-tooling.md) |
| Spectator mode | A game setup option for agent-only games that lets you watch agents play | [cover-and-spectator.md](design/agents/cover-and-spectator.md#spectator-mode) |
| Step | One unit of work in a phase, in its own file `NN-short-name.md` | [rules/docs.md](rules/docs.md#roadmap) |
| Sweat level | How hard an agent pushes toward victory: no sweat, balanced, or super sweat | [sweat-level.md](design/agents/sweat-level.md) |
| Tuner | The debug server inside the game. FireTuner and the bridge connect to it over TCP | [tuner-setup.md](findings/tuner-setup.md) |
| Turn signal | The tagged line that the core mod prints when a human player's turn starts, such as `[SENTIENTSYSTEMS] AGENT_TURN 0` | [architecture.md](design/architecture.md#turn-signal) |
| Windows Sandbox | A clean, throwaway copy of Windows built into Windows 10 and 11 Pro, Enterprise, and Education. It tests the executable on a machine with no Node | [build-tooling.md](findings/build-tooling.md#method) |
