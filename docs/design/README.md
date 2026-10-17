# Design

How each part of the system works. Each file ends with a `## Decisions` table that records why the design is that way.

| File | Covers |
| --- | --- |
| [architecture.md](architecture.md) | The six hops from agent to game, the turn signal, and the core boundary rule |
| [core/](core/README.md) | Core: the in-game core mod and the external bridge |
| [agents/](agents/README.md) | The agent players mod: slots, turn loop, cover card, narration, messaging, sweat level |
| [advisors.md](advisors.md) | The read-only advisors mod (later project) |
| [memory.md](memory.md) | Agent memory files and checkpoint IDs for reloads and branching saves |
| [knowledge-files.md](knowledge-files.md) | Concept guides, civ notes, personalities, sweat files, and the model table |
| [testing.md](testing.md) | Test presets, the test matrix, and playtests |
| [distribution.md](distribution.md) | How users install, launch, and set up the mods and bridge |
| [versioning.md](versioning.md) | Package versions, bump rules, the release flow, and runtime version checks |
