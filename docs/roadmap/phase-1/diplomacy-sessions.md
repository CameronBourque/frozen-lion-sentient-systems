# Diplomacy sessions

Add the sessions that an AI opens with no deal to the state, and an action that answers one, so an agent player is never held up by a leader screen it can't see. Part of [phase 1](README.md).

An AI opens these sessions to comment, such as on an agenda, and to ask for something, such as a promise, a delegation, or an embassy. The proposals section lists only the sessions that hold a deal.

The war and peace actions refuse a major civ while any session is open. See [declaring war](../../findings/actions/war-and-peace.md#declaring-war).

## Tasks

1. **Find the statements.** Record what an AI session holds and how the leader screen reads it, starting with `OnDiplomacyStatement` and the statement handlers in `DiplomacyActionView.lua`. Record the responses each one offers, such as `POSITIVE`, `NEGATIVE`, and `RESPONSE_IGNORE`.

   With a session open, send a request and the end turn call, and record whether the session stops them. Test it on Scythia's comment after a war, and on a request for a delegation or a promise. Commit: `docs: record the AI diplomacy sessions`.
2. **State.** Add the open sessions that an AI started with no deal to the state, each with the player, what they said, and the responses. Commit: `feat(core): add the diplomacy sessions to the state`.
3. **Respond to a session.** Add `SentientSystems_RespondToSession(playerID, otherPlayerID, response)`, which adds the response and closes the session, as the leader screen does when the player leaves it.

   Add `respondToSession` to `src/actions/deals.ts`. Commit: `feat(core): add the session response action`.

## Done when

In a running game, the state lists an AI's comment and request sessions, and `respondToSession` answers each and closes its leader screen. With no session left open, `declareWar` and `endTurn` go through.

## Record

- The statements, their responses, and what an open session stops, in [findings/actions/diplomacy.md](../../findings/actions/diplomacy.md).
- The sessions section, in [design/core/mod/state.md](../../design/core/mod/state.md), and the action, in [design/core/mod/actions/deals.md](../../design/core/mod/actions/deals.md).
- The rows of the action, in the `## Parts of an action` table in the [core README](../../../packages/core/README.md).
