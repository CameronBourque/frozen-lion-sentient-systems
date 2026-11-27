# Auto-explore

Add `explore` to `unit_action`, so the model can set a unit to auto-explore. Plain code gives no unit orders, as [turn-loop/](../../design/agents/turn-loop/README.md#decisions) says. Part of [phase 2](README.md).

## Tasks

1. **Explore order.** Add `explore` to the stances in `Scripts/Actions/SentientSystemsCore_ActionsUnitStances.lua` and to `unit_action` in the bridge, with the loose and real checks that [unit-orders.md](../../findings/actions/unit-orders.md#unit-orders) describes. Commit: `feat(core): add auto-explore to unit actions`.

## Done when

In a running game, `unit_action` with `explore` sets an idle scout to auto-explore. The scout leaves the `units` blocker list, and `wake` stops it.

## Record

- How explore behaves, its activity, and whether wake stops it on the same turn, in [unit-orders.md](../../findings/actions/unit-orders.md).
- The explore order, in [design/core/mod/actions/units.md](../../design/core/mod/actions/units.md#stances).
