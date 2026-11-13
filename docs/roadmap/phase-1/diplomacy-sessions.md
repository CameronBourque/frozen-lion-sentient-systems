# Diplomacy sessions

Add the sessions that an AI opens with no deal to the state, and an action that answers one, so an agent player is never held up by a leader screen it can't see. Part of [phase 1](README.md).

An AI opens these sessions to comment, such as on an agenda, to ask for something, such as a promise, a delegation, or an embassy, and to greet the player when the two first meet. The proposals section lists only the sessions that hold a deal.

A first meeting has more than one statement in one session. The first offers a greeting or a goodbye. The greeting leads to a second statement, such as an offer to exchange capital locations, and which one comes depends on who found whom and where.

The player meets a civ when one of their units sees a tile the civ owns, when the civ's unit finds them, or when they meet a city-state whose suzerain they haven't met.

The war and peace actions refuse a major civ while any session is open. See [declaring war](../../findings/actions/war-and-peace.md#declaring-war).

The core mod closes a session that offers only a goodbye, and passes the agent a short message with what the leader said, as a human player sees it. The state already holds its effects, such as a denouncement, a war, grievances, and the AI's opinion modifiers.

Our Lua state saw no statement between two AIs, but it may hear only the local player's sessions. See [between two AIs](../../findings/actions/ai-sessions.md#between-two-ais). What a native AI gets stays open until the [computer slot test](../../design/agents/slot-type.md#computer-slot-test), and the messages may change then.

The sessions with a real choice, such as a request or a first meeting, go in the state. The game waits for an answer from the player's slot, and the choice has effects, such as Diplomatic Favor or a capital reveal.

## Tasks

1. **Find the statements.** Record what an AI session holds and how the leader screen reads it, starting with `OnDiplomacyStatement` and the statement handlers in `DiplomacyActionView.lua`. Record the responses each one offers, such as `POSITIVE`, `NEGATIVE`, and `RESPONSE_IGNORE`.

   With a session open, send a request and the end turn call, and record whether the session stops them. Test it on Scythia's comment after a war, and on a request for a delegation or a promise.

   Answer each kind of first meeting, and record its statements and what each choice changes, such as the capital reveal and the AI's opinion. The kinds are near the recipient, a visit to the recipient, near the initiator, and in no man's land. Commit: `docs: record the AI diplomacy sessions`.
2. **Close the goodbyes.** In `SentientSystemsCore_UI`, listen to `Events.DiplomacyStatement`. For an agent player, close each session whose statement from an AI offers only `CHOICE_EXIT`. This covers the AI's reply after an answer, and the reply to a war the player declares.

   Sessions that hold a deal stay with the proposals section.

   Keep a message for each: the turn, the player, the statement, the leader's text from `DiplomacyManager.FindTextKey`, and the reason, such as the agenda. Keep each message until the end of the agent's next turn.

   Closing in the handler leaves no leader screen. See [closing a goodbye](../../findings/actions/ai-sessions.md#closing-a-goodbye). Commit: `feat(core): close the AI's goodbye sessions for agent players`.
3. **State.** Add the open sessions with a real choice that an AI started with no deal to the state. Each has the player, the statement that is open now, what they said, and the options, with the reason an option is disabled.

   A session open with no statement recorded, such as one from before a reload, is listed with only the player and a warning, so the agent can still close it. Add the messages from task 2. Commit: `feat(core): add the diplomacy sessions to the state`.
4. **Respond to a session.** Add `SentientSystems_RespondToSession(playerID, otherPlayerID, response)`, which adds the response, or closes the session for the goodbye, as the leader screen does.

   A response that leads to another statement, such as the greeting at a first meeting, leaves the session open on that statement.

   Add `respondToSession` to `src/actions/deals.ts`. Commit: `feat(core): add the session response action`.
5. **End the turn.** `SentientSystems_EndTurn` refuses while a session is open, with the session as the reason. It records the request only when it sends it. See [with a leader screen up](../../findings/actions/end-turn.md#with-a-leader-screen-up). Commit: `fix(core): refuse the end turn while a session is open`.

## Done when

In a running game, an AI's comment closes with no leader screen left up, and the state lists an AI's request and first meeting sessions.

`respondToSession` answers each, through every statement of a first meeting, and closes its leader screen. With no session left open, `declareWar` and `endTurn` go through.

## Record

- The statements, their responses, and what an open session stops, in [findings/actions/ai-sessions.md](../../findings/actions/ai-sessions.md).
- The sessions section, in [design/core/mod/state.md](../../design/core/mod/state.md), and the action, in [design/core/mod/actions/deals.md](../../design/core/mod/actions/deals.md).
- The rows of the action, in the `## Parts of an action` table in the [core README](../../../packages/core/README.md).
