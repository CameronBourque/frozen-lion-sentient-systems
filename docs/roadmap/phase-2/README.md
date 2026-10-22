# Phase 2: You and several agents

This phase adds games with a human and several agents, the cover card, and memory snapshots that survive reloads.

**Gate.** You play a game against two agents, with at least one reload to an earlier save.

## Scope

- Run the [computer slot test](../../design/agents/slot-type.md#computer-slot-test), and pick the game mode for you and several agents
- Handle the hotseat pass screen, if that game mode is hotseat
- Cover card during agent turns
- Verify that no agent sees outside its fog of war
- Checkpoint IDs and memory snapshots

Design: [agents/slot-type.md](../../design/agents/slot-type.md), [agents/cover-and-spectator.md](../../design/agents/cover-and-spectator.md), [memory.md](../../design/memory.md#checkpoint-ids). Open questions: [game-api.md](../../findings/game-api.md#questions), questions 6 and 7. The active player in hotseat is answered in [game-api.md](../../findings/game-api.md#active-player).

## Steps

Not broken down yet. When it is, the scope items become steps, and we remove this list.
