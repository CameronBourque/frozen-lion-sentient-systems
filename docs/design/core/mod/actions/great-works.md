# Great work actions

How the core mod runs the actions that move a great work and choose an artifact, as the Great Works and artifact screens do. Part of the [action API](README.md).

## Move a great work

`SentientSystems_MoveGreatWork(playerID, workIndex, city, building, slot)` in `Scripts/Actions/SentientSystemsCore_ActionsGreatWorks.lua` moves the work with the game's index to a slot.

The work is the `index` of a `work` in the `greatWorks` state, and the slot is the `city.id`, `building`, and `slot` of one of its `slots`.

The `moves` that `SentientSystems_GetGreatWorkMoves` gives for a work are the slots that work. A slot that holds a work swaps the two.

The screen sends one `MOVE_GREAT_WORK` request, so the action does too.

The game takes moves the screen refuses, so the action checks the screen's rules first. See [great-works.md](../../../../findings/actions/great-works.md).

Its reasons, in order, name a work the player doesn't have, a slot the player doesn't have, and the work already being in that slot.

Then they name a work that is locked or an artifact in a museum that isn't full, a slot that doesn't take the work's kind, and an artifact moved to an empty slot. The last names a swap whose other work doesn't fit the source slot or can't move.

On the bridge, `moveGreatWork` in `src/actions/great-works.ts` sends the call.

## Choose an artifact

`SentientSystems_ChooseArtifact(playerID, artifactPlayer)` in `Scripts/Actions/SentientSystemsCore_ActionsArtifacts.lua` chooses whose artifact the digging archaeologist uncovers. The player is a `player` from the `options` of the `artifacts` choice.

The screen's buttons each send one `CHOOSE_ARTIFACT_PLAYER` request with their player, so the action does too.

The game takes a player the artifact doesn't offer, so the action checks the options first. Its reasons name an artifact that isn't waiting, and a player that isn't one of the artifact's players.

On the bridge, `chooseArtifact` in `src/actions/great-works.ts` sends the call.

## Shared rules

The great works state and the actions both read the slots and decide where a work can go, so the rules are in `Scripts/SentientSystemsCore_GreatWorks.lua`.

`SentientSystems_GetGreatWorkMoveFailure` gives the reason a move fails, and `SentientSystems_GetGreatWorkMoves`, in the state file, lists the slots where it gives none.

The action looks up the work with `SentientSystems_FindGreatWork` and the slot with its own function. The failure function also gives the reason for a work or slot it didn't find, so the action only sends the request.

## Decisions

| Decision | Reason |
| --- | --- |
| The state's slot rules are in one shared file | The moves list and the action can't disagree about what the screen allows |
| The action takes a slot as the state gives it, not as the game numbers it | The agent copies a `city.id`, `building`, and `slot` from the state, and the action turns the building into the index the request needs |
| The artifact action takes its players from the same function as the choice | `SentientSystems_GetNextArtifact` in `Scripts/SentientSystemsCore_Artifacts.lua` reads the blocker, the archaeologist, and the site, so the choice can't list a player the action refuses |
| A move onto the work's own slot is a failure | The screen ignores it, and an agent that sends it has made a mistake worth telling it about |
