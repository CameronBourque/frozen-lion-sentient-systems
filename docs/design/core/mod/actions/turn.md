# End turn action

How the core mod ends the turn, as the **Next Turn** button does. Part of the [action API](README.md).

## End the turn

`SentientSystems_EndTurn(playerID, force)` in `Scripts/Actions/SentientSystemsCore_ActionsTurn.lua` sends `UI.RequestAction(ActionTypes.ACTION_ENDTURN)`. See [ending the turn](../../../../findings/actions/end-turn.md#ending-the-turn).

The request ends the turn even with a blocker left, so the action checks the blockers itself, as `DoEndTurn` in `ActionPanel.lua` does. Without `force`, it fails while a blocker is left or a unit needs orders. With `force`, it sends the request anyway.

The blockers come from `SentientSystems_GetBlockerState`, the same list the state's `blockers` section has.

The action leaves out the three unit blockers, `ENDTURN_BLOCKING_UNITS`, `ENDTURN_BLOCKING_UNIT_NEEDS_ORDERS`, and `ENDTURN_BLOCKING_STACKED_UNITS`, and lists the units that need orders in their place. See [end-turn-blockers.md](../../../../findings/state/end-turn-blockers.md).

The action fails while any diplomacy session is open with the player, with or without `force`, and names the player. A deal points to the deal response, and any other session to the session response.

The open session comes from `SentientSystems_FindOpenSession`, which the war and peace actions use too. See [with a leader screen up](../../../../findings/actions/end-turn.md#with-a-leader-screen-up).

The action keeps the turn of its last request, and fails for a second call in that turn, with or without `force`. The turn is kept in the UI script's Lua state, so a reload clears it.

Its reasons, in order, name a turn already ended, an open session, then the blockers, each with the choice that resolves it, and the IDs of the units that need orders.

On the bridge, `endTurn` in `src/actions/turn.ts` sends the call.

## Decisions

| Decision | Reason |
| --- | --- |
| The action checks the blockers, and `force` skips the check | The game's request skips them, so without the check an agent could end a turn with no research and no production. `force` keeps a way out when a blocker has no action yet |
| Units that need orders block the turn, from the units list | The **Next Turn** button waits for them too. The game updates the unit blockers only on its own events, so they can be stale |
| An open session refuses the end turn, even with `force` | With a session open, the request only closes the leader screen, and the AI turns wait for the session. The action records the request, so a refusal keeps the next call from failing as a turn already ended |
| One request at most in a turn, even with `force` | A second request while the first is in progress can skip a turn |
