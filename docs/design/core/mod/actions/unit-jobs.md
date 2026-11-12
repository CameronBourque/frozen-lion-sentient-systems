# Unit jobs

How the core mod runs the orders of builders, engineers, great people, and religious units. Part of the [action API](../README.md).

## Builder jobs

`build_road`, `remove_feature`, `harvest`, `repair`, `remove_improvement`, and `clear_fallout` are the builder jobs, in `SentientSystemsCore_ActionsUnitJobs.lua`.

- `build_road` is for a Military Engineer and builds the best route the player has, so `type` is optional. A route that differs is refused with the one the game would build.
- `repair` fixes a pillaged improvement, and a pillaged route when the improvement is whole.
- `clear_fallout` clears the nuclear fallout on the unit's tile for a build charge. A unit with build charges in its row counts as a builder, so a Roman Legion does these jobs too, as the game allows.

Their reasons come from the unit and the tile: the moves and build charges left, a missing feature or resource, a tech the player lacks, an improvement in the way, and a tile the player doesn't own.

A resource the player can't see yet is not named. The game's own reason, such as a drought for a repair, comes back as it is.

## Add production

`add_production` has an engineer or builder add production to the item a city builds, at the cost of a build charge, in `SentientSystemsCore_ActionsUnitProduction.lua`. It works from the city for a building, and from the tile of a district.

The game allows one of four commands, by the kind of item. A builder gets them only through some leaders and buildings.

The game gives no reasons, so the core mod says when the unit is not a builder, has no moves, is outside a city, or stands off the tile of the district. It also says when the city builds nothing the unit can help.

## Great people

`activate` and `harvest_wonder` are unit orders with no parameters, in `SentientSystemsCore_ActionsUnitGreatPeople.lua`. `activate` uses a great person's ability, which for a great engineer is its production for a wonder.

The game gives the reasons, such as the tile the person must stand on. See [great-people.md](../../../../findings/actions/great-people.md).

## Religious units

`found_religion`, `spread_religion`, `remove_heresy`, `heal_followers`, `evangelize_belief`, `launch_inquisition`, and `condemn_heretic` are unit orders with no parameters, in `SentientSystemsCore_ActionsUnitReligion.lua`.

A prophet founds a religion on its Holy Site, and the religion's name and beliefs are chosen in the found religion action. An Apostle's `evangelize_belief` earns one more belief, which the belief action picks.

The game's reasons come back, such as the district a prophet must stand on. See [religious-units.md](../../../../findings/actions/religious-units.md).

## Decisions

| Decision | Reason |
| --- | --- |
| The core mod gives its own reason where the game gives none, such as for adding production | A refusal with no reason leaves the agent to repeat the mistake |
| The game's own reason comes back where it gives one, such as a drought for a repair or the tile a person must stand on | The game's check is the authority on legality, so the core mod doesn't restate it |
