# World Congress actions

How the core mod runs the World Congress actions, as the congress screen does. Part of the [action API](README.md).

## Vote in a session

`SentientSystems_VoteInCongress(playerID, votes)` in `Scripts/Actions/SentientSystemsCore_ActionsWorldCongress.lua` casts every vote of the session and submits them.

A vote on a resolution of the `worldCongress` choice names it by its `type`, with `option`, A or B, from its `options`, `target`, the `index` of one of its `targets`, and `votes`. Every resolution needs one, as on the screen.

A vote on a proposal names it by its `type` and `target`, with `votes`, and `against` to oppose it. A proposal left out is an abstention.

The screen's **Accept** sends one `WORLD_CONGRESS_RESOLUTION_VOTE` for each resolution, then one `WORLD_CONGRESS_DISCUSSION_VOTE` for each proposal, keyed by its sender and target, and then `WORLD_CONGRESS_SUBMIT_TURN`, so the action does too.

It doesn't send the screen's end turn request: the submit clears the session blocker. See [world-congress.md](../../../../findings/actions/world-congress.md).

Its reasons, in order, name no session to vote in, votes that aren't a list, a vote that isn't a table, and an item voted on twice.

For a resolution, they name an option that isn't A or B and a target index out of range. For a proposal, they name one that isn't on the floor, with those that are. For either, they name a number of votes outside 1 to the most the session allows.

The last name a resolution with no vote, and votes whose total cost is more than the player's Favor.

On the bridge, `voteInCongress` in `src/actions/world-congress.ts` sends the call.

## Shared rules

The choice and the actions both read the session, so the rules are in `Scripts/SentientSystemsCore_WorldCongress.lua`.

`SentientSystems_GetCongressSession` returns the resolutions, the proposals, and the vote costs while the session blocker is up. `SentientSystems_GetCongressAvailable` returns the proposals the player could make.

`SENTIENTSYSTEMS_RESOLUTION_OPTIONS` lists a resolution's two options, each with its letter, the number the screen sends, and the column of its text. The session's `options` are built from it.

`SentientSystems_FindResolutionOption` finds an option by its letter or its number. The choice reads each voter's option with it, and the action checks a vote's letter and finds its number.

On the bridge, `RESOLUTION_OPTION` in `src/schemas.ts` holds the same letters for the choice's schema and the vote's type.

## Decisions

| Decision | Reason |
| --- | --- |
| One action casts every vote and submits | The screen sends the votes as one batch, and the Favor check needs all of them |
| A vote's type says whether it is on a resolution or a proposal | The agent copies the type from the choice, and the two never share one |
| A resolution's target is the index of one of its targets | Targets can be players, resources, or great person classes, and the index names any of them |
| The action doesn't end the turn | Ending the turn is its own action, and the submit alone clears the blocker |
| A vote names a proposal by its type and target | The agent copies both from the choice, and the action finds the sender the request needs |
| A vote takes a count and `against`, not a signed count | The agent says which side it is on in words, and the action turns it into the sign the request needs |
