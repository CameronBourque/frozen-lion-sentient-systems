# Standing orders and the state diff

A standing order is a multi-turn plan that plain code in the bridge carries out each turn, so the model runs only when a wake trigger fires. When the model does run, it gets a state diff, the changes since its last turn, in place of the full state.

## Why

Most turns in a Civ VI game are quiet. A city keeps building, an army keeps marching, and research follows the path the agent already chose.

Running the model on each of those turns costs tokens and gives the model a chance to drop a plan it made a few turns ago. Standing orders keep the plan in code, and wake triggers bring the model back when something changes.

The state diff solves the other half. An agent that sleeps through quiet turns must still see what happened, so it can cancel an order that no longer fits. The diff shows it those changes at a fraction of the size of the full state.

## Orders

The agent gives an order through a tool, as it gives any action. Each order has:

- an ID that the bridge assigns,
- a kind and a target, such as a city or a unit,
- a list of steps, done in order,
- wake triggers of its own, picked from a fixed list,
- a `reason`, as every action tool has.

These are the first kinds of order. The list is partial.

| Kind | Steps | Done when |
| --- | --- | --- |
| Build list | Items a city builds, in order | The last item is built |
| Unit goal | Move to a tile, then fortify, hold, or sleep there | The unit reaches the tile and takes the stance |
| Builder plan | Improvements, each on a tile, in order | The builder runs out of charges or steps |
| Research path | A target tech or civic | The target is researched |
| Repeat | One action each time it becomes possible, such as renewing a trade route | The agent cancels it |

Where the game already keeps a multi-turn plan, the order uses it. A unit's move to a far tile already lasts several turns through the game's pathfinding. 

A city's build list is the game's own production queue. It holds up to 7 items after the current one and builds them in order with no request per turn. See [production.md](../../findings/actions/production.md#the-queue).

## Running orders

At the start of each agent turn, before the model runs, the bridge does these steps:

1. Read the state and the end-turn blockers.
2. Run the next step of each order.
3. Resolve each blocker that an order covers. For example, a research path picks the next tech on the path.
4. Check the wake triggers.
5. If no trigger fired, and no blocker is left, end the turn without the model.
6. If a trigger fired, run the model with the state diff and the list of triggers that fired.

A step that fails, such as a blocked tile or a build item that is no longer legal, wakes the model with the failure reason. The bridge does not retry a failed step on its own.

## Wake triggers

The bridge always wakes the model for these events:

- An order finishes or one of its steps fails.
- A blocker comes up that no order covers.
- A civ declares war on the agent, or offers a deal.
- An enemy unit comes into sight within a few tiles of a city or an ordered unit.
- A city or an ordered unit takes damage.
- A new era starts.

An order can add triggers of its own from a fixed list, such as "the unit falls below half health" or "a rival settles within 6 tiles of the target." A fixed list keeps each trigger a plain check in code, with no model call.

The bridge also wakes the model every few turns with no trigger, so the agent reviews its orders against the slow changes that no trigger catches. How many turns is open.

## Changing and cancelling orders

Whenever the model runs, it sees every active order with its progress in the state diff. It can change or cancel any order through these tools:

- `issue_order` gives a new order.
- `change_order` replaces the steps or triggers of an order.
- `cancel_order` ends an order, with a `reason`.

A unit or city takes one order at a time. A new order for the same unit or city replaces the old one, and the result says so.

Orders are part of agent memory, so the bridge snapshots them under each [checkpoint ID](../memory.md#checkpoint-ids). After a reload, the agent's orders match the save.

## State diff

The bridge keeps the state from the agent's last model turn. On the next model turn, it compares that state with the new one and sends the changes, grouped by section:

- cities founded, lost, grown, or damaged, and items finished,
- units built, lost, damaged, or promoted, and enemy units that came into or went out of sight,
- tiles newly seen, summed up as counts of terrain and resources,
- changes in yields, treasury, and diplomacy,
- each order's progress,
- the wake triggers that fired.

A unit that moves into fog is "out of sight," not "lost." The diff reports only what the player can see, as the state does.

The agent gets the full state in these cases:

- the first turn of a game,
- the first turn after a load,
- the deep strategic review.

At any other time, the agent can read a full section through a tool when the diff is not enough.

The diff runs in the bridge, in TypeScript, on the two serialized states. The core mod does not change. How much the diff saves against the full state is measured with the state sizes in [testing.md](../testing.md#state-size).

## Open questions

- How many turns pass between wakes with no trigger? It may depend on the sweat level.
- How close must an enemy unit be to wake the model? A fixed distance may be too wide in a crowded start.
- How many orders can one agent hold before the diff gets too long?

## Decisions

| Decision | Reason |
| --- | --- |
| Plain code in the bridge runs orders, and the model runs only on a wake trigger | Quiet turns cost no model call, and the plan stays in code between turns |
| A failed step wakes the model, with no retry by the bridge | The model knows why it gave the order, so it decides what replaces it |
| Wake triggers come from a fixed list | Each trigger is a plain check in code, with no model call |
| The model wakes every few turns even with no trigger | Slow changes, such as a rival's growing army far away, fire no trigger |
| Orders are snapshotted with agent memory | A reload restores the orders that match the save |
| The diff compares with the agent's last model turn, not the last game turn | The model sees every change it slept through |
| The full state comes on the first turn, after a load, and at the deep strategic review | The model has no earlier state to compare with, or it needs the whole picture |
