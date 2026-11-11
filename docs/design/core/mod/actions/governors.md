# Governor actions

How the core mod runs the actions on the Governors panel: appoint, promote, and assign. They need Rise and Fall. Part of the [action API](README.md).

## Appoint, promote, and assign

`Scripts/Actions/SentientSystemsCore_ActionsGovernors.lua` has three actions, one for each request the panel sends:

- `SentientSystems_AppointGovernor(playerID, governor)` spends a title on a governor from the `appoint` list of the `governors` choice, such as `GOVERNOR_THE_DEFENDER`.
- `SentientSystems_PromoteGovernor(playerID, governor, promotion)` spends a title on a promotion from the `promote` list.
- `SentientSystems_AssignGovernor(playerID, governor, owner, cityID)` sends a governor to a city from the `assign` list, by its `owner` and `id`. A governor with no city and one moving to another city use the same call.

The game takes requests the panel wouldn't send, so each action checks the panel's rules first. See [governors.md](../../../../findings/actions/governors.md).

## Shared rules

`Scripts/SentientSystemsCore_Governors.lua` holds the rules that the `governors` choice and the actions share, so they can't disagree:

- `SentientSystems_GetGovernorsClosedReason`, for a game without Rise and Fall and a World Congress in session.
- `SentientSystems_IsAppointable`, `SentientSystems_IsPromotionEarnable`, and `SentientSystems_IsAssignable`, for the panel's buttons.
- `SentientSystems_GetAssignTargets`, the chooser's list of cities, each with the game's reasons it is turned off.

## Reasons

Each action first names a game where the panel is closed, and a type that is no governor. Then:

- **Appoint** names a governor the player has, one the panel never offers, and a player with no title to spend.
- **Promote** names a governor not yet appointed, a promotion that isn't theirs, one they hold, a player with no title to spend, and a promotion they can't earn yet.
- **Assign** names a governor not yet appointed, a Secret Society, and a neutralized governor with its turns left. Then it names the city the governor is in, a city the chooser doesn't list, and a city the chooser turns off, with the game's reasons.

On the bridge, `src/actions/governors.ts` has `appointGovernor`, `promoteGovernor`, and `assignGovernor`.

## Decisions

| Decision | Reason |
| --- | --- |
| Three actions, one for each request | Each takes different parameters, as the great people actions do, and a bridge function for each keeps its types plain |
| The checks live in `SentientSystemsCore_Governors.lua`, and the choice uses them too | The choice and the actions can't disagree on what the panel allows |
| Assign sends the assignment chooser's request, with the city's owner | It reaches city-states and other players' capitals, where the panel's own request reaches only the player's cities |
| Assign matches the city against the chooser's list | The list already holds every rule for where a governor can go, and the game's reasons for a city it turns off |
