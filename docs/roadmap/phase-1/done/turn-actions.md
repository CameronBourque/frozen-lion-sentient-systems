# Phase 1: turn action steps

The finished Action API steps of [phase 1](../README.md) that clear the last blockers, answer deals and leader screens, and end the turn. The step table's `#` column sets their order.

## Action API: other blockers

Pull request: feat(core): add the city fate, espionage, congress, and dedication actions.

It added the action that keeps, razes, liberates, or refuses a captured or rebelled city, the action that chooses a spy's escape route, the World Congress actions that vote in a session and make a proposal, and the action that makes an era's dedications.

Each action checks the screen's rules first, because the game takes requests the screen wouldn't send.

Each choice and its action share their rules in one file: the city fate options, the escape routes, the session and the available proposals, and the waiting dedication. The captured cities choice became the city fate choice, `cityFates`.

The action that joins or rejects an emergency moved to [phase 3](../../phase-3/README.md): with Gathering Storm, every emergency starts through the World Congress. The popups that a session and its results leave open moved to [popups for agent players](../agent-popups.md).

- The reasons are in [design/core/mod/actions/city-fate.md](../../../design/core/mod/actions/city-fate.md), [cities.md](../../../design/core/mod/actions/cities.md#escape-route), [world-congress.md](../../../design/core/mod/actions/world-congress.md), and [dedications.md](../../../design/core/mod/actions/dedications.md).
- The calls and the checks the game doesn't make are in [actions/city-fate.md](../../../findings/actions/city-fate.md), [actions/spies.md](../../../findings/actions/spies.md#escape-route), [actions/world-congress.md](../../../findings/actions/world-congress.md), and [actions/dedications.md](../../../findings/actions/dedications.md).
- The parts of an action are in the [core README](../../../../packages/core/README.md#parts-of-an-action).

## Action API: deals and end turn

Pull request: feat(core): add the deal and end turn actions.

It added `endTurn`, which returns the blockers and the units that need orders as its reason unless forced, and sends one request at most in a turn. It added `respondToDeal`, `declareWar`, and `proposePeace`, which close the diplomacy session they use, so the AI turns go on.

The bridge's `proposePeace` waits for the AI's answer. A plain peace keeps the cities the player occupies. The great work type in the proposals state now comes from the item's type ID.

The leader screen that a war or a peace leaves open moved to [popups for agent players](../agent-popups.md), and the sessions an AI opens with no deal to [diplomacy sessions](#diplomacy-sessions).

- The reasons are in [design/core/mod/actions/turn.md](../../../design/core/mod/actions/turn.md) and [deals.md](../../../design/core/mod/actions/deals.md).
- The calls are in [actions/end-turn.md](../../../findings/actions/end-turn.md), [actions/diplomacy.md](../../../findings/actions/diplomacy.md), and [actions/war-and-peace.md](../../../findings/actions/war-and-peace.md).
- The parts of an action are in the [core README](../../../../packages/core/README.md#parts-of-an-action).

## Diplomacy sessions

Pull request: feat(core): add the diplomacy session state and action.

It closes each leader screen from an AI that offers an agent player only a goodbye, such as a comment or the reply to a war, and keeps what the leader said as a message in that player's diplomacy entry.

The other screens, such as a request, a promise, or a first meeting, are a new `sessions` state section, with the leader's text and the options the screen offers, disabled ones with the game's reason.

`respondToSession` answers one with an option key, and a first meeting goes on through each of its statements. `endTurn` refuses while any session is open, even with `force`. The proposals section leaves out an old deal that stays in the incoming deal while the session holds another statement.

The messages and the closing are for a human slot only. Phase 2 replaces them with what the [computer slot test](../../../design/agents/slot-type.md#computer-slot-test) finds a native AI gets.

- The sessions section and the messages are in [design/core/mod/state.md](../../../design/core/mod/state.md#decisions), and the reasons in [design/core/mod/actions/deals.md](../../../design/core/mod/actions/deals.md#respond-to-a-session) and [turn.md](../../../design/core/mod/actions/turn.md).
- The calls are in [actions/ai-sessions.md](../../../findings/actions/ai-sessions.md), [actions/ai-requests.md](../../../findings/actions/ai-requests.md), [actions/first-meetings.md](../../../findings/actions/first-meetings.md), and [actions/end-turn.md](../../../findings/actions/end-turn.md#with-a-leader-screen-up).
- The parts of an action are in the [core README](../../../../packages/core/README.md#parts-of-an-action).
