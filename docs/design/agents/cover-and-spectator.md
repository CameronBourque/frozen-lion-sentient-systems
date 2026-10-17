# Cover card and spectator mode

What a human sees while agents play. When a human is in the game, a card hides the map during agent turns. In agent-only games, spectator mode lets you watch.

## Cover card

When a human plays in the game, a full-screen card covers the map during each agent turn. It shows text such as "Montezuma is thinking" and one status line. The agent plays under it through the API. The card is mandatory in that case, because a few seconds of an agent's view show you its unit positions.

## Spectator mode

Spectator mode is a game setup option. It unlocks only when every player is an agent. When it is on, the agent pauses between actions and the camera pans to each unit before it moves. When it is off, the agent plays at full speed under the cover card.

## Map reveal

A button switches the view between the full map and the current player's real view. The reveal must change rendering only. Some reveal mods mark tiles as revealed in the player's game data. That changes gameplay, not only rendering. Test the chosen method before you use it.

## Decisions

| Decision | Reason |
| --- | --- |
| Cover card during agent turns when a human plays | An agent's view would show you its positions |
| Spectator mode only in agent-only games | Same reason |
