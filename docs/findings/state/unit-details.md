# Unit and city details in the state

Status: in progress. The unit activity and charges are confirmed in a running game with Gathering Storm. Religious units, great people, rival religious units, city religion, and the room for a purchased unit are not yet checked.

The calls the unit and city details in the state use, as the unit panel and the city panel show them. See [design/core/mod/state.md](../../design/core/mod/state.md).

## Questions

- What do the religious unit, great person, rival religious unit, city religion, and purchase room calls return?

## What we know now

### Unit activity and charges

`Base/Assets/UI/Panels/UnitPanel.lua` reads a unit's charges in `ReadUnitData`, lines 2252 to 2259, and its activity in `AddUnitToUnitList`, line 4054. Confirmed in files and in a running game.

- **Activity.** `UnitManager.GetActivityType(unit)` returns a hash. `ActivityTypes` has `ACTIVITY_AWAKE`, `SLEEP`, `HOLD`, `SENTRY`, `HEAL`, `INTERCEPT`, `OPERATION`, and `NO_ACTIVITY` (-1).

  The unit list shows `SLEEP` and `HOLD` (skip turn) as icons. The state names the activities `awake`, `sleep`, `skip`, `sentry`, `heal`, `intercept`, and `operation`.
- **Fortified.** The unit list shows a fortify icon when the unit is not `AWAKE` and `unit:GetFortifyTurns() > 0`. `SENTRY` alone is fortified or on alert.

  A unit that is `AWAKE` keeps its fortify turns, so the turns alone don't tell. A unit on `OPERATION` with turns counts as fortified, by the same rule.
- **Attacks left.** `unit:GetAttacksRemaining()` is 1 for every unit, builders, spies, and great people included, until it attacks. The panel doesn't show it. `WorldInput.lua` and `SelectedUnit.lua` read it to see whether a ranged attack is possible.

  The state gives it only for a unit with a `GetCombat()`, `GetRangedCombat()`, or `GetBombardCombat()` above 0.
- **Charges.** `unit:GetBuildCharges()` is the builder charges left, and 0 for other units. The panel shows a charge only above 0, and the state does too.
- **Formation.** `unit:GetMilitaryFormation()` returns `MilitaryFormationTypes.STANDARD_MILITARY_FORMATION` (0), `CORPS_MILITARY_FORMATION` (1), or `ARMY_MILITARY_FORMATION` (2). A civilian gets `NO_MILITARY_FORMATION` (-1). A sea unit's corps is a fleet and its army an armada, with the same values.

## Method

1. To read the units section before the `.modinfo` loads it, send `SentientSystemsCore_StateUnits.lua` through the tuner as in [choices/production.md](../choices/production.md#method), step 4, and call `SentientSystems_GetUnitStates(Players[Game.GetLocalPlayer()])`.
2. Compare each unit with the unit panel and the unit list.

## Results

A single-player game with Gathering Storm, with 41 units of one player, in `SentientSystemsCore_UI`:

| Check | Result |
| --- | --- |
| Activities | `sleep` for great admirals and builders, `intercept` for a jet fighter, `operation` for spies, traders, and bombers on a mission or route, `awake` for a frigate and a builder |
| Fortified | A mechanized infantry and a knight army were `sentry` and fortified with 2 turns. A musketman on alert was `sentry` and not fortified. A modern armor on `operation` with 2 turns was fortified |
| Attacks left | 1 for the fighting units, and 0 for a nuclear submarine that had fired. Civilians had none |
| Build charges | 1 to 3 for builders, left out for every other unit |
| Formation | `army` for the knight army, left out for the rest |

Date checked: game files on 2026-11-06. Running game on Windows on 2026-11-06.
