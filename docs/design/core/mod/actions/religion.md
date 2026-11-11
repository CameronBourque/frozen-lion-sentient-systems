# Religion actions

How the core mod runs the actions that found a pantheon and a religion, and add a belief. Part of the [action API](README.md).

## Pantheon

`SentientSystems_FoundPantheon(playerID, belief)` in `Scripts/Actions/SentientSystemsCore_ActionsReligion.lua` founds the player's pantheon, as the pantheon chooser's confirm does. The belief is a `type` from the `pantheon` choice, such as `BELIEF_RELIGIOUS_SETTLEMENTS`.

The game takes a belief of any class, so the action checks the chooser's rules first. See [religion.md](../../../../findings/actions/religion.md).

`SentientSystems_IsBeliefTaken` in `Scripts/SentientSystemsCore_Religion.lua` is the check that a belief is in no player's pantheon or religion. The `pantheon` and `religion` choices use it too, so the choices and the action can't disagree.

Its reasons, in order, name a player with a pantheon already, a player who can't found one yet, a type that is no belief, a belief that isn't a pantheon belief, and a belief another player has. The last three point at the `pantheon` choice.

On the bridge, `foundPantheon` in `src/actions/religion.ts` sends the call.

## Religion

`SentientSystems_FoundReligion(playerID, religion, beliefs, name)` in the same file founds the player's religion and adds its beliefs, as the religion screen's confirm does. One call sends `FOUND_RELIGION` and an `ADD_BELIEF` for each belief, in that order.

The religion is a `type` from the `religions` of the `religion` choice. The beliefs are a list of `type`s from its `beliefs`, as many as its `picks`, with a follower belief first. The name is for a religion whose `customName` is `true`.

The game takes a religion and beliefs the screen wouldn't offer, so the action checks the screen's rules first. See [religion.md](../../../../findings/actions/religion.md#religion).

`SentientSystems_GetBeliefPicks` in `Scripts/SentientSystemsCore_Religion.lua` counts the beliefs earned less those the religion has. The `religion` choice reads its `picks` from it too.

Its reasons, in order, name a player with a religion already, one with no pantheon, and one with no beliefs earned, which points at the Great Prophet. Then they name a type that is no religion, and a religion another player founded.

Then they name a missing name, or a name for a religion with a fixed one. Without `CAPABILITY_RENAME`, the action sends the religion's own name, as the screen's name box does.

Last, they name a count of beliefs that isn't the `picks`. Then, for each belief in order, a type that is no belief, a pantheon belief, a class the religion has too many of, and a belief another player has. Then a first belief that isn't a follower belief, and a second belief of one class.

On the bridge, `foundReligion` in `src/actions/religion.ts` takes the beliefs as a list and the name last, and leaves the name out when it isn't given.

## Add a belief

`SentientSystems_AddBelief(playerID, belief)` in the same file adds one belief to the player's founded religion, with one `ADD_BELIEF`. The belief is a `type` from the `beliefs` of the `religion` choice, which lists beliefs once the religion has a pick left.

Its reasons, in order, name a player with no religion, and a religion with no pick left, which points at the Apostle's `evangelize_belief`. Then they name a type that is no belief, a pantheon belief, a class the religion has, and a belief another player has, the same checks as founding.

On the bridge, `addBelief` in `src/actions/religion.ts` sends the call.

## Decisions

| Decision | Reason |
| --- | --- |
| The action checks the belief's class and whether it is taken, though the chooser doesn't | The game's check takes a belief of another class, and the agent can name any belief, where the chooser lists only legal ones |
| The pantheon checks come before the belief checks | A player who can't found a pantheon gets the same reason for any belief, so the agent learns to wait instead of trying another belief |
| The belief check that no player has the belief, and the count of picks, live in `SentientSystemsCore_Religion.lua` | The religion choices and the religion actions both load them, so the choice and the actions can't disagree |
| Founding takes the religion and its starting beliefs in one call | The screen sends them on one click. A religion founded with no beliefs was never seen in a game, so the action doesn't risk one |
| The action checks the screen's rules for the beliefs: the count, a follower first, and one of each class | The game's check takes a belief of any class in any order, and the agent can name any belief, where the screen lists only legal ones |
| Adding a belief takes one belief per call, though the screen waits for every pick | An Apostle earns one belief at a time, so one pick is the usual case, and the game took a single belief on its own |
