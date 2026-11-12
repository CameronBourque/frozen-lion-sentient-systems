# Phase 1: unit action steps

The finished Action API steps of [phase 1](../README.md) that give units their orders. The step table's `#` column sets their order.

## Action API: units

Pull request: [feat(core): add the unit actions](https://github.com/CameronBourque/frozen-lion-sentient-systems/pull/45).

It added the action result format, and move, stance, found city, improve, pillage, and attack, with failure reasons.

- The result format, the reasons, and the unit orders are under **Action API** in [design/core/mod/actions/README.md](../../../design/core/mod/actions/README.md).
- The calls are in [actions/move-unit.md](../../../findings/actions/move-unit.md), [actions/unit-orders.md](../../../findings/actions/unit-orders.md), and [actions/attacks.md](../../../findings/actions/attacks.md).
- The parts of an action are in the [core README](../../../../packages/core/README.md#parts-of-an-action).

## Action API: unit jobs

Pull request: [feat(core): add the unit job actions](https://github.com/CameronBourque/frozen-lion-sentient-systems/pull/56).

It added builder jobs, upgrades, formations, air movement, the priority target, and adding production.

- The reasons and the orders are under **Action API** in [design/core/mod/actions/README.md](../../../design/core/mod/actions/README.md).
- The calls are in [actions/unit-orders.md](../../../findings/actions/unit-orders.md), [actions/builder-jobs.md](../../../findings/actions/builder-jobs.md), [actions/formations.md](../../../findings/actions/formations.md), [actions/air-moves.md](../../../findings/actions/air-moves.md), and [actions/attacks.md](../../../findings/actions/attacks.md).
- The parts of an action are in the [core README](../../../../packages/core/README.md#parts-of-an-action).

## Action API: special units

Pull request: feat(core): add the trade route, great person, religious unit, and spy actions.

It added the trade route and spy choices, and the trade route, plunder, great person, religious unit, spy, pillage road, and coastal raid actions.

- The reasons and the orders are under **Action API** in [design/core/mod/actions/README.md](../../../design/core/mod/actions/README.md), and the choices are in [design/core/mod/choices.md](../../../design/core/mod/choices.md).
- The choices' calls are in [choices/trade-routes.md](../../../findings/choices/trade-routes.md) and [choices/spy-missions.md](../../../findings/choices/spy-missions.md).
- The actions' calls are in [actions/trade.md](../../../findings/actions/trade.md), [actions/great-people.md](../../../findings/actions/great-people.md), [actions/spies.md](../../../findings/actions/spies.md), [actions/religious-units.md](../../../findings/actions/religious-units.md), [actions/unit-orders.md](../../../findings/actions/unit-orders.md), and [actions/attacks.md](../../../findings/actions/attacks.md).
- The parts of an action are in the [core README](../../../../packages/core/README.md#parts-of-an-action).

## Action API: nuclear strikes

Pull request: feat(core): add the nuclear actions.

It added the nuclear and thermonuclear stockpile to the player section, a `wmdLaunchers` section with the units and missile silos that can launch each device now, and the turns of fallout left on each tile.

It added the `wmd_strike` unit order, `SentientSystems_SiloStrike` for a silo, and the `clear_fallout` builder job. A strike follows the unit panel, so a unit with no moves left can't launch, though the game's check allows it. A strike that would start a war is refused.

The launchers state and the strike actions share their rules in one file. A Roman Legion counts as a builder, as the game treats it, so it clears fallout and does the other builder jobs.

- The state is in [design/core/mod/state.md](../../../design/core/mod/state.md), and the reasons are in [design/core/mod/actions/units.md](../../../design/core/mod/actions/units.md#wmd-strikes) and [unit-jobs.md](../../../design/core/mod/actions/unit-jobs.md#builder-jobs).
- The calls are in [state/wmds.md](../../../findings/state/wmds.md), [state/fallout.md](../../../findings/state/fallout.md), [actions/wmd-strikes.md](../../../findings/actions/wmd-strikes.md), and [actions/builder-jobs.md](../../../findings/actions/builder-jobs.md#clear-fallout).
- The parts of an action are in the [core README](../../../../packages/core/README.md#parts-of-an-action).
