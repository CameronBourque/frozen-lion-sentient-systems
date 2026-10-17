# Code rules

Rules for code in every package. Each architecture rule links to the design decision that explains it.

## Architecture

- [Only core talks to the game. Feature mods use the core API and never call FireTuner or game Lua directly](../design/architecture.md#core-boundary).
- [Move code into core only when a second mod needs it](../design/architecture.md#core-boundary).
- [Actions go through the game's own request functions, so the game checks legality](../design/core/in-game-lua.md).
- [Agent state comes from the player's visibility data, never from the screen](../design/core/in-game-lua.md#decisions).
- [Every failed action returns a reason](../design/core/in-game-lua.md#decisions).
- [Every action tool has a required `reason` field](../design/agents/narration-and-messaging.md#narrator-panel).
- [The API key never goes into a game setup parameter](../design/core/bridge.md).
- [A file format change bumps that file's schema version and ships a migration](../design/versioning.md#bump-rules).

## Conventions

None settled yet. Phase 0 [step 4](../roadmap/phase-0/04-scaffold-bridge.md) sets up the bridge's TypeScript project. Record its conventions here once that merges.
