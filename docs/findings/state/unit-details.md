# Unit and city details in the state

Status: in progress. The unit activity and charges, religious units, and great people are confirmed in a running game with Gathering Storm. Rival religious units, city religion, and the room for a purchased unit are not yet checked.

The calls the unit and city details in the state use, as the unit panel and the city panel show them. See [design/core/mod/state.md](../../design/core/mod/state.md).

## Questions

- What do the rival religious unit, city religion, and purchase room calls return?

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

### Religious units and great people

- **Religion.** `unit:GetReligionType()` returns an index in `GameInfo.Religions`, whose index 0 is `RELIGION_PANTHEON`. `UnitFlagManager.lua` shows a unit's religion when the index is above 0 and `GetReligiousStrength()` is above 0, in `UpdateReligion` at line 799.

  The panel itself shows the strength, not the religion. Confirmed in files and in a running game.
- **Charges.** `GetSpreadCharges()` and `GetReligiousHealCharges()` are the spreads and heals left, and the panel shows each only above 0. `unit:GetActionCharges()` was 0 for every unit in the sample, great people included, so the state leaves it out.
- **Great people.** `unit:GetGreatPerson()` returns an object for every unit, with a class of -1 for a unit that isn't one. `GetClass()` and `GetIndividual()` are indexes in `GameInfo.GreatPersonClasses` and `GreatPersonIndividuals`, and `GetActionCharges()` is the charges left.

  The panel reads the charges at line 2282, and shows them only above 0. The state keeps them at 0 as well, because a prophet has none before a religion exists.
- **Purchased units skip their turn.** An apostle and an inquisitor bought in the city were on `HOLD` (skip) when the check ran, and a missionary and a guru were `AWAKE`.

## Method

1. To read the units section before the `.modinfo` loads it, send `SentientSystemsCore_StateUnits.lua` through the tuner as in [choices/production.md](../choices/production.md#method), step 4, and call `SentientSystems_GetUnitStates(Players[Game.GetLocalPlayer()])`.
2. Compare each unit with the unit panel and the unit list.
3. For religious units, found a religion with a prophet on a holy site, and buy a missionary, an apostle, an inquisitor, and a guru in a city with a shrine and a temple.

   In `GameCore_Tuner`, `Players[0]:GetCulture():SetCivic(index, true)` gives Theology, and `WorldBuilder.CityManager():CreateBuilding(city, "BUILDING_TEMPLE", 100, plotIndex)` adds the temple.

## Results

A single-player game with Gathering Storm, with 41 units of one player, in `SentientSystemsCore_UI`:

| Check | Result |
| --- | --- |
| Activities | `sleep` for great admirals and builders, `intercept` for a jet fighter, `operation` for spies, traders, and bombers on a mission or route, `awake` for a frigate and a builder |
| Fortified | A mechanized infantry and a knight army were `sentry` and fortified with 2 turns. A musketman on alert was `sentry` and not fortified. A modern armor on `operation` with 2 turns was fortified |
| Attacks left | 1 for the fighting units, and 0 for a nuclear submarine that had fired. Civilians had none |
| Build charges | 1 to 3 for builders, left out for every other unit |
| Formation | `army` for the knight army, left out for the rest |
| Religious units | A missionary, an apostle, and an inquisitor had the founded religion, a strength of 100, 110, and 75, and 3 spreads. A guru had strength 90 and 3 heals |
| Great people | The class, the individual, and 1 charge for scientists, admirals, and merchants, 4 for an engineer, and 0 for a prophet before it founded a religion |
| A spy on a mission | `awake` before, and `operation` right after a Gain Sources mission started |

Date checked: game files on 2026-11-06. Running game on Windows on 2026-11-06.
