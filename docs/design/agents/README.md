# Agent players mod

This mod turns a human player slot into an agent. It depends on the core mod, declares that dependency in its `.modinfo` file, and reaches the game only through the core API.

| File | Covers |
| --- | --- |
| [slot-type.md](slot-type.md) | The **Agent** slot type and how slots pick the game mode |
| [turn-loop.md](turn-loop.md) | The turn loop, tools, failure handling, and decision records |
| [cover-and-spectator.md](cover-and-spectator.md) | The cover card during agent turns, spectator mode, and the map reveal |
| [narration-and-messaging.md](narration-and-messaging.md) | The narrator panel, `reason` fields, and messages between players |
| [sweat-level.md](sweat-level.md) | How hard each agent pushes toward victory, and **AI Difficulty** |

What makes up an agent at runtime is in [knowledge-files.md](../knowledge-files.md#file-layout).

Code: [packages/agents/](../../../packages/agents/README.md).
