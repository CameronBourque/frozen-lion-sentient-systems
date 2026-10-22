# Agent slot type

How the setup screen marks a player as an agent, and which game mode each mix of players runs in. Games with you and an agent, or agents only, are open, because the tuner closes in hotseat.

The setup screen gets an **Agent** option in each slot's player-type dropdown. The engine's slot types are fixed enums, so **Agent** is a label over one of them. Each **Agent** slot also gets two dropdowns, one for personality and one for [sweat level](sweat-level.md).

## Game modes

| Players | Game mode | Status |
| --- | --- | --- |
| One agent against the native AI | Single player, with the agent in the human slot | Planned for the [MVP](../../roadmap/phase-1/README.md) |
| You, agents, and the native AI | Open | Waits for the computer slot test |
| Agents only | Open | Waits for the computer slot test |

The first plan put the last two rows in hotseat, with each agent in a human slot. That doesn't work through the tuner, because the game closes the tuner port in hotseat. Single player keeps one human, so it can't hold you and an agent as two humans. See [findings/multiplayer.md](../../findings/multiplayer.md#hotseat).

## Computer slot test

Before [phase 2](../../roadmap/phase-2/README.md), a test puts an agent in a computer slot in a single-player game, where the tuner stays open. If it works, **Agent** shows in the dropdown of both human and computer slots. The test answers these questions:

1. Can the native AI be held back for that one civ? Otherwise it fights the agent for the same units.
2. Can the request functions act for a player who isn't the local player?
3. When does the agent take its turn? Turn processing can't wait for an LLM, and computer players may move while you do.
4. How does the mod mark a player as an agent? The game data has no requirement that checks a per-player flag. Only `REQUIREMENT_PLOT_PROPERTY_MATCHES` exists. Gameplay Lua can attach modifiers to one player with `AttachModifierByID`.

An agent gets the same bonuses in a human slot and a computer slot. Difficulty bonuses are data. `HIGH_DIFFICULTY_*` modifiers apply to computer players through `PLAYER_IS_HIGH_DIFFICULTY_AI`, and `LOW_DIFFICULTY_*` modifiers apply to humans through `PLAYER_IS_LOW_DIFFICULTY_HUMAN`, in `Leaders.xml`. Extra starting units for computer players come from `MajorStartingUnits` rows with `AiOnly`.

If the test fails, the backups are in [risks.md](../../risks.md).

## Decisions

| Decision | Reason |
| --- | --- |
| **Agent** is a label over the engine's slot types | The engine's slot types are fixed enums |
| One agent against the native AI runs in single player, with the agent in the human slot | The tuner stays open in single player |
| No LAN games with separate clients | Simultaneous turns cost a game copy per agent |
