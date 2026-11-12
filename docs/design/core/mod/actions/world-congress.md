# World Congress actions

How the core mod runs the World Congress actions, as the congress screen does. Part of the [action API](README.md).

## Vote in a session

`SentientSystems_VoteInCongress(playerID, votes)` in `Scripts/Actions/SentientSystemsCore_ActionsWorldCongress.lua` casts every vote of the session and submits them.

Each vote names a proposal on the floor of the `worldCongress` choice by its `type` and `target`, with `votes`, and `against` to oppose it. A proposal left out is an abstention, so an empty list submits with no votes.

The screen's **Accept** sends one `WORLD_CONGRESS_DISCUSSION_VOTE` for each proposal, keyed by its sender and target, and then `WORLD_CONGRESS_SUBMIT_TURN`, so the action does too. It doesn't send the screen's end turn request: the submit clears the session blocker. See [world-congress.md](../../../../findings/actions/world-congress.md).

Its reasons, in order, name no session to vote in, votes that aren't a list, and a vote that isn't a table. Then they name a proposal that isn't on the floor, with those that are, a proposal voted on twice, and a number of votes outside 1 to the most the session allows.

The last names votes whose total cost is more than the player's Favor.

On the bridge, `voteInCongress` in `src/actions/world-congress.ts` sends the call.

## Shared rules

The choice and the actions both read the session, so the rules are in `Scripts/SentientSystemsCore_WorldCongress.lua`.

`SentientSystems_GetCongressSession` returns the resolutions, the proposals, and the vote costs while the session blocker is up. `SentientSystems_GetCongressAvailable` returns the proposals the player could make.

## Decisions

| Decision | Reason |
| --- | --- |
| One action casts every vote and submits | The screen sends the votes as one batch, and the Favor check needs all of them |
| The action doesn't end the turn | Ending the turn is its own action, and the submit alone clears the blocker |
| A vote names a proposal by its type and target | The agent copies both from the choice, and the action finds the sender the request needs |
| A vote takes a count and `against`, not a signed count | The agent says which side it is on in words, and the action turns it into the sign the request needs |
