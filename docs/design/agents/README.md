# Agent players mod

This mod turns a player slot into an agent. It depends on the core mod, declares that dependency in its `.modinfo` file, and reaches the game only through the core API.

| File | Covers |
| --- | --- |
| [slot-type.md](slot-type.md) | The **Agent** slot type and how slots pick the game mode |
| [turn-loop/](turn-loop/README.md) | The turn loop, its tools, failure handling, stopping, and decision records |
| [game-load.md](game-load.md) | How a game load cancels an agent's turn, and the wait while the game doesn't answer |
| [prompt.md](prompt.md) | How the bridge builds an agent's prompt from sections |
| [cover-and-spectator.md](cover-and-spectator.md) | The cover card during agent turns, spectator mode, and the map reveal |
| [narration-and-messaging.md](narration-and-messaging.md) | The narrator panel, `reason` fields, and messages between players |
| [sweat-level.md](sweat-level.md) | How hard each agent pushes toward victory, and **AI Difficulty** |

What makes up an agent at runtime is in [knowledge-files.md](../knowledge-files.md#file-layout).

Code: [packages/agents/](../../../packages/agents/README.md).
