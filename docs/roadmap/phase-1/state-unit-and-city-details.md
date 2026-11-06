# State: unit and city details

Add what an agent needs to know about a unit or a city before it picks an action. The action steps return these as reasons today, so the agent finds out by being refused. Part of [phase 1](README.md).

## Tasks

1. **Unit activity and charges.** Add what a unit is doing, asleep, fortified, skipping its turn, or on an order, its attacks left, its builder charges, and its formation level, a corps or an army.

   Read the calls from `UnitPanel.lua`. Commit: `feat(core): add the unit activity and charges to the state`.
2. **Religious units and great people.** Add a unit's religion and its spread and heal charges, and a great person's class, individual, and action charges.

   Read the calls from `UnitPanel.lua`, which shows them in its stats and its great person fields. Commit: `feat(core): add religious units and great people to the state`.
3. **Rival religious units.** Add the religion of a visible rival unit that spreads or heals, which `condemn_heretic` needs.

   Read the calls from `UnitFlagManager.lua`, which marks religious units. Commit: `feat(core): add rival religious units to the state`.
4. **City religion.** Add each city's followers and pressure for every religion it has, and its majority, as the City Panel's religion tab shows them. Read the calls from `CityPanel.lua` and the Religion screen. Commit: `feat(core): add the city religion to the state`.
5. **Room for a purchased unit.** Add whether a city has a free tile for a new unit. A purchased unit needs a free tile in the city center or its districts, and a city whose tiles each hold a unit can't buy one.

   Find the call the purchase check uses, and add its answer to the city's purchases or its state, whichever the call fits. Commit: `feat(core): add the room for a new unit to the state`.

## Done when

In a running game, each field matches the screen it comes from: the unit panel for a unit's activity, charges, religion, and great person fields, the city panel for the religion, and the purchase list for the room.

## Record

- Each section's calls and results, in a findings file of its own in [findings/state/](../../findings/state/README.md), with a row in its index.
- Each section, in [design/core/mod/state.md](../../design/core/mod/state.md).
- The parts of each section, listed in the `## Parts of a state section` table in the [core README](../../../packages/core/README.md).
