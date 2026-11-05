# End-turn check

When the agent calls `end_turn`, the bridge checks the state for wasted resources, such as an idle builder or gold piled up with nothing bought. On the first call of a turn, the check returns what it found in place of ending the turn. A second call always ends the turn.

## Why

Models leave value on the table in long games. They forget a builder, let gold pile up, or leave a policy slot empty, and nothing in the game stops the turn for it.

The game's end-turn blockers catch only some of these cases, and the agent finds the blockers one at a time, each on a failed `end_turn` call. The [agent loop](../../roadmap/phase-1/agent-loop.md) step forces the end turn when the loop hits a limit, and a forced end skips the blockers that are left.

The check lists the blockers and the waste together in one result, so the agent fixes them in one pass. Fewer failed calls means fewer forced ends.

## What the check finds

The check has two kinds of item:

- **Blockers.** The game's end-turn blockers, such as a research choice or a unit that needs orders. The turn cannot end while one is left, except by a forced end at the loop limit.
- **Waste.** Resources that sit unused. The turn can end with waste left.

The first waste items are in this table. The list is partial.

| Item | Found when |
| --- | --- |
| Sleeping builder | A builder with charges sleeps or skips its turn, and no order covers it |
| Sleeping army | A military unit sleeps or skips its turn while an enemy unit is in sight |
| Gold | The treasury is over a threshold, and the agent can buy something |
| Faith | Faith is over a threshold, and the agent can buy something with it |
| Empty policy slot | A policy slot is empty, and a card fits it |
| Trade route | The agent has fewer trade routes than its capacity |
| Envoys and governors | Envoys or a governor title are unassigned, and the game does not block on them |
| Great person | The agent can recruit a great person now |

A unit with moves left and no orders is already a game blocker, so the waste items cover units the agent put to sleep and forgot. The check skips a unit or a city that a [standing order](standing-orders.md) covers. A unit that follows an order is not idle.

Thresholds scale with the agent's income. For example, the gold threshold is a number of turns of gold income, not a fixed amount. The sweat level sets the thresholds, so a super sweat agent gets a stricter check than a no sweat agent.

## Flow

1. The agent calls `end_turn`.
2. The bridge runs the check on the current state and choices.
3. If the check finds nothing, the turn ends.
4. If the check finds blockers or waste on the first call of the turn, the turn does not end. The result lists each item, with its unit or city and the tool that fixes it.
5. The agent fixes the items it wants to fix, and calls `end_turn` again with a `reason` for each waste item it left.
6. On the second call, waste no longer stops the turn. Blockers still do, until the loop limit forces the end.

The check also runs at the start of each model turn, and its items go into the [state diff](standing-orders.md#state-diff). The agent sees the list before it acts, so it can plan the fixes with its other actions.

On a turn with no model call, the check still runs. Its waste items wait for the next model turn and do not wake the model. A unit that needs orders or a city with nothing to build is a game blocker, and a blocker that no order covers wakes the model.

## Logs

The bridge logs every waste item the agent leaves, with the agent's `reason`. An item the agent leaves turn after turn with the same reason points at a threshold that is too strict or at a guide that is missing a rule. These records tune the thresholds, as decision records tune the [helpers](helpers.md#weights).

## Code

The check is a pure function in the bridge, in TypeScript, over the serialized state and choices. It needs no change to the core mod. Each item is its own small rule, so adding an item does not change the others.

## Open questions

- What are the first thresholds for gold and faith at each sweat level?
- Should some waste items block twice, such as a builder left idle for several turns in a row?
- Should no sweat skip the check, so the agent plays loosely as [sweat-level.md](../agents/sweat-level.md) describes?

## Decisions

| Decision | Reason |
| --- | --- |
| The check runs inside `end_turn`, and it also runs at the start of each model turn | The agent sees the list before it acts, and it cannot end the turn without seeing it |
| Blockers and waste come back in one result | The agent fixes everything in one pass, with fewer failed calls and fewer forced ends |
| Waste stops only the first `end_turn` call | The agent can always end the turn with a reason, so the check never traps it |
| The agent gives a `reason` for each waste item it leaves | The logs show which thresholds and guides need tuning |
| Standing orders exempt their units and cities | A unit that follows an order is not idle |
| Waste items cover sleeping units, not units with no orders | The game already blocks the turn on a unit with no orders |
| Thresholds scale with income and come from the sweat level | A fixed amount is wrong at every stage of the game but one |
