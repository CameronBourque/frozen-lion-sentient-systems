# Phase 1: action api steps

The finished Action API steps of [phase 1](../README.md). The step table's `#` column sets their order.

## Action API: units

Pull request: [feat(core): add the unit actions](https://github.com/CameronBourque/frozen-lion-sentient-systems/pull/45).

It added the action result format, and move, stance, found city, improve, pillage, and attack, with failure reasons.

- The result format, the reasons, and the unit orders are under **Action API** in [design/core/mod/actions.md](../../../design/core/mod/actions.md).
- The calls are in [actions/move-unit.md](../../../findings/actions/move-unit.md), [actions/unit-orders.md](../../../findings/actions/unit-orders.md), and [actions/attacks.md](../../../findings/actions/attacks.md).
- The parts of an action are in the [core README](../../../../packages/core/README.md#parts-of-an-action).

## Action API: unit jobs

Pull request: [feat(core): add the unit job actions](https://github.com/CameronBourque/frozen-lion-sentient-systems/pull/56).

It added builder jobs, upgrades, formations, air movement, the priority target, and adding production.

- The reasons and the orders are under **Action API** in [design/core/mod/actions.md](../../../design/core/mod/actions.md).
- The calls are in [actions/unit-orders.md](../../../findings/actions/unit-orders.md), [actions/builder-jobs.md](../../../findings/actions/builder-jobs.md), [actions/formations.md](../../../findings/actions/formations.md), [actions/air-moves.md](../../../findings/actions/air-moves.md), and [actions/attacks.md](../../../findings/actions/attacks.md).
- The parts of an action are in the [core README](../../../../packages/core/README.md#parts-of-an-action).

## Action API: special units

Pull request: feat(core): add the trade route, great person, religious unit, and spy actions.

It added the trade route and spy choices, and the trade route, plunder, great person, religious unit, spy, pillage road, and coastal raid actions.

- The reasons and the orders are under **Action API** in [design/core/mod/actions.md](../../../design/core/mod/actions.md), and the choices are in [design/core/mod/choices.md](../../../design/core/mod/choices.md).
- The choices' calls are in [choices/trade-routes.md](../../../findings/choices/trade-routes.md) and [choices/spy-missions.md](../../../findings/choices/spy-missions.md).
- The actions' calls are in [actions/trade.md](../../../findings/actions/trade.md), [actions/great-people.md](../../../findings/actions/great-people.md), [actions/spies.md](../../../findings/actions/spies.md), [actions/religious-units.md](../../../findings/actions/religious-units.md), [actions/unit-orders.md](../../../findings/actions/unit-orders.md), and [actions/attacks.md](../../../findings/actions/attacks.md).
- The parts of an action are in the [core README](../../../../packages/core/README.md#parts-of-an-action).
