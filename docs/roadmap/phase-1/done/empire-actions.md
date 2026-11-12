# Phase 1: empire action steps

The finished Action API steps of [phase 1](../README.md) for cities, research, policies, religion, rewards, and great works. The step table's `#` column sets their order.

## Action API: cities

Pull request: feat(core): add the city actions.

It added the production, purchase, and tile purchase actions. Production takes a district or wonder with its tile, and an `append` flag that adds to the city's queue, which holds a build list.

- The reasons are under **Action API** in [design/core/mod/actions/README.md](../../../design/core/mod/actions/README.md), and the build list is in [design/decision-support/standing-orders.md](../../../design/decision-support/standing-orders.md#orders).
- The calls and the queue test are in [actions/production.md](../../../findings/actions/production.md) and [actions/purchases.md](../../../findings/actions/purchases.md).
- The parts of an action are in the [core README](../../../../packages/core/README.md#parts-of-an-action).

## Action API: research and policies

Pull request: feat(core): add the research, civic, policy, and government actions.

It added the tech and civic actions with their queues, and the actions that set the policies in every slot, pay the policy unlock, and change the government. Each action checks the screen's rules first, because the game takes illegal requests.

- The reasons are in [design/core/mod/actions/research.md](../../../design/core/mod/actions/research.md) and [design/core/mod/actions/government.md](../../../design/core/mod/actions/government.md).
- The calls and the checks the game doesn't make are in [actions/research.md](../../../findings/actions/research.md) and [actions/policies.md](../../../findings/actions/policies.md).
- The parts of an action are in the [core README](../../../../packages/core/README.md#parts-of-an-action).

## Action API: religion and rewards

Pull request: feat(core): add the religion, governor, and reward actions.

It added the actions that found a pantheon, recruit, pass, and patronize a great person, found a religion with its beliefs, and add a belief.

It also added the Apostle's evangelize and inquisition orders, the governor actions that appoint, promote, and assign, and the envoy action. Each action checks the screen's rules first, because the game takes illegal requests.

- The reasons are in [design/core/mod/actions/religion.md](../../../design/core/mod/actions/religion.md), [great-people.md](../../../design/core/mod/actions/great-people.md), [governors.md](../../../design/core/mod/actions/governors.md), and [envoys.md](../../../design/core/mod/actions/envoys.md).
- The calls and the checks the game doesn't make are in [actions/religion.md](../../../findings/actions/religion.md), [actions/great-people-screen.md](../../../findings/actions/great-people-screen.md), [actions/religious-units.md](../../../findings/actions/religious-units.md), [actions/governors.md](../../../findings/actions/governors.md), and [actions/envoys.md](../../../findings/actions/envoys.md).
- The parts of an action are in the [core README](../../../../packages/core/README.md#parts-of-an-action).

## Action API: great works

Pull request: feat(core): add the great work and artifact actions.

It added the action that moves a great work to another slot, or swaps it with the work there, and the action that chooses whose artifact an archaeologist uncovers. Each action checks the screen's rules first, because the game takes illegal requests.

The great works state and the move action share their slot rules, and the artifact choice and action share the artifact the archaeologist digs.

- The reasons are in [design/core/mod/actions/great-works.md](../../../design/core/mod/actions/great-works.md).
- The calls and the checks the game doesn't make are in [actions/great-works.md](../../../findings/actions/great-works.md).
- The parts of an action are in the [core README](../../../../packages/core/README.md#parts-of-an-action).
