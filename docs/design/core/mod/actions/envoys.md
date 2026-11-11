# Envoy action

How the core mod runs the action that sends envoys to a city-state, as the City-States screen does. Part of the [action API](README.md).

## Send envoys

`SentientSystems_SendEnvoys(playerID, cityState, count)` in `Scripts/Actions/SentientSystemsCore_ActionsEnvoys.lua` sends `count` envoys to the city-state, 1 when the count is left out. The city-state is an ID from the `cityStates` of the `envoys` choice, and the count is at most its `tokens`.

The screen sends one `GIVE_INFLUENCE_TOKEN` for each envoy, so the action does too.

The game takes envoys for a city-state the screen turns off, so the action checks the screen's rules first. See [envoys.md](../../../../findings/actions/envoys.md).

Its reasons, in order, name a player with no envoys to send, a count that isn't a whole number of at least 1, and a count over the envoys the player has. Then they name an ID that is no city-state, such as the Free Cities, a city-state the player hasn't met, and one they are at war with.

On the bridge, `sendEnvoys` in `src/actions/envoys.ts` sends the call, with a count of 1 by default.

## Decisions

| Decision | Reason |
| --- | --- |
| The action takes a count of envoys | The screen places several envoys at one city-state before one confirm, and the choice shows the `tokens` to spend |
| The action checks `CanGiveTokensToPlayer`, as the envoys choice does | The choice lists a city-state only when the screen turns its buttons on, so the choice and the action can't disagree |
| The action leaves the envoy blocker alone | The screen sets it only when the player closes the screen, so whether to keep envoys is the end-turn step's choice |
