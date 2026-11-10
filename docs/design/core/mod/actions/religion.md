# Religion actions

How the core mod runs the actions that found a pantheon. Part of the [action API](README.md).

## Pantheon

`SentientSystems_FoundPantheon(playerID, belief)` in `Scripts/Actions/SentientSystemsCore_ActionsReligion.lua` founds the player's pantheon, as the pantheon chooser's confirm does. The belief is a `type` from the `pantheon` choice, such as `BELIEF_RELIGIOUS_SETTLEMENTS`.

The game takes a belief of any class, so the action checks the chooser's rules first. See [religion.md](../../../../findings/actions/religion.md).

`SentientSystems_IsBeliefTaken` in `Scripts/SentientSystemsCore_Religion.lua` is the check that a belief is in no player's pantheon or religion. The `pantheon` and `religion` choices use it too, so the choices and the action can't disagree.

Its reasons, in order, name a player with a pantheon already, a player who can't found one yet, a type that is no belief, a belief that isn't a pantheon belief, and a belief another player has. The last three point at the `pantheon` choice.

On the bridge, `foundPantheon` in `src/actions/religion.ts` sends the call.

## Decisions

| Decision | Reason |
| --- | --- |
| The action checks the belief's class and whether it is taken, though the chooser doesn't | The game's check takes a belief of another class, and the agent can name any belief, where the chooser lists only legal ones |
| The pantheon checks come before the belief checks | A player who can't found a pantheon gets the same reason for any belief, so the agent learns to wait instead of trying another belief |
| The belief check that no player has the belief lives in `SentientSystemsCore_Religion.lua` | The religion choices and the religion actions both load it, and the later belief actions need it too |
