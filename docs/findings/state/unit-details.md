# Unit and city details in the state

Status: in progress. The unit activity and charges, religious units, and great people are confirmed in a running game with Gathering Storm. Rival religious units are confirmed too. City religion is confirmed too. The room for a purchased unit is not yet checked.

The calls the unit and city details in the state use, as the unit panel and the city panel show them. See [design/core/mod/state.md](../../design/core/mod/state.md).

## Questions

- What does the purchase room call return?

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

### Rival religious units

`UnitFlagManager.lua` shows a visible unit's religion on its flag with the same rule as for the player's own units: `GetReligionType()` above 0 and `GetReligiousStrength()` above 0, at line 799. Its tooltip adds the religion's name, at line 890. Confirmed in files and in a running game.

The rivals section lists a unit only on a tile that is visible now, so a rival religious unit appears only when the player sees it. The religion is public to anyone who sees the unit, at war or not.

`condemn_heretic` needs it. `UNITCOMMAND_CONDEMN_HERETIC` is open to a unit that shares a tile with a religious unit of another religion whose owner is at war with the player, and the state now says whose religion that is.

### Religious strength and religious attacks

`unit:GetReligiousStrength()` is the strength the panel shows for a religious unit, at lines 1436 and 2257. It was 100 for a missionary, 110 for an apostle, and 75 for an inquisitor.

It decides a religious attack, so the state gives it for the player's units and for visible rival units, and leaves it out at 0.

Religious units can attack each other freely. An inquisitor attacked a missionary of a player it wasn't at war with, and only condemning needs a war. Confirmed in a running game.

The request is the one a melee unit uses: `UnitManager.RequestOperation(unit, UnitOperationTypes.MOVE_TO, { PARAM_X, PARAM_Y, PARAM_MODIFIERS = ATTACK + MOVE_IGNORE_UNEXPLORED_DESTINATION })` on an adjacent tile, which `CanStartOperation` allowed. A request without the `ATTACK` modifier did nothing.

The `attack` action refused a religious unit, with "This kind of unit can't attack.", because the unit has no combat strength. It now attacks with the religious strength. See [actions/attacks.md](../actions/attacks.md).

### City religion

The City Panel's religion button opens the Religion screen through `LuaEvents.CityPanel_ShowReligionTab`, and the banner shows the same city values. Confirmed in files and in a running game.

- **Followers.** `city:GetReligion():GetReligionsInCity()` lists one entry per religion present, each with `Religion`, `Followers`, and `Pressure`.

  `Religion` is an index in `GameInfo.Religions`, and below 1 for the citizens with no religion. `CitySupport.lua` names those `RELIGION_PANTHEON`, at line 504, and `ReligionScreen.lua` reads `Followers` at line 1090.
- **Majority.** `GetMajorityReligion()` returns the index of the religion with the most followers, and -1 while none leads. The banner shows an icon above 0, in `CityBannerManager.lua`, line 1181. A city with 4 citizens of no religion and 1 follower of Shinto had no majority.
- **Pressure each turn.** The banner shows `GetTotalPressureOnCity(religion)` beside each religion, rounded to a whole number, as "Incoming pressure per turn". It was 26 for Shinto in Noviodunum, as the screen showed.

  The call isn't valid for the entry with no religion. A city's own religion had a pressure of 0 on it.
- **Pressure received in all.** The `Pressure` in the `GetReligionsInCity()` list is the total the city has received. The banner's tooltip, "Followers / Total Pressure Received", shows it rounded: 8 followers and 1,493 pressure for Shinto in Noviodunum, from 1,493 in the list.

  The banner loop skips the entry with no religion, so the state gives neither pressure for it.
- **Pressure exerted.** `GetPressureFromCity()` is the "Outgoing pressure per turn" at the top of the banner, rounded, and 2 for Noviodunum as the screen showed. It belongs to the city's majority religion, and was 0 for a city with none, and 8 for the city of the player's own religion.
- **Conversion.** `GetNextReligion()` is the religion the city converts to, and `GetTurnsToNextReligion()` the turns until then. The banner shows "Converts in N" when the next religion isn't -1 and the turns are above 0, in `CityBannerManager.lua`, line 1391.

  Aduatuca converted to Taoism in 23 turns, and Bagacum in 8, as the screen showed, and Samarobriva to Shinto in 127. A city that isn't converting had -1 and 0, and the state leaves the conversion out.

All 11 cities of the player came to 3,386 bytes once three religions had spread, about 310 for each, so the religion is part of the cities section.

## Method

1. To read the units section before the `.modinfo` loads it, send `SentientSystemsCore_StateUnits.lua` through the tuner as in [choices/production.md](../choices/production.md#method), step 4, and call `SentientSystems_GetUnitStates(Players[Game.GetLocalPlayer()])`.
2. Compare each unit with the unit panel and the unit list.
3. For the rival units, load `SentientSystemsCore_StateUnits.lua` and `SentientSystemsCore_StateRivals.lua` the same way, and call `SentientSystems_GetRivalUnitStates(0)`. Compare the religious units with `UnitManager.GetUnit(owner, id)` on the tiles the player sees.

   To try `condemn_heretic`, send `UnitManager.InitUnit(0, "UNIT_KNIGHT", x, y)` and `RestoreMovement` in `GameCore_Tuner` on the tile of a visible unit of a player at war with you, then `UnitManager.RequestCommand` with the command's hash.
4. For a religious attack, send the melee request above from an inquisitor to an adjacent tile with a rival religious unit, and read both units' `GetDamage()`.
5. For the city religion, load `SentientSystemsCore_StateCities.lua` the same way, call `SentientSystems_GetCityStates(Players[0])`, and compare each city's `religion` with `city:GetReligion()`.
6. For religious units, found a religion with a prophet on a holy site, and buy a missionary, an apostle, an inquisitor, and a guru in a city with a shrine and a temple.

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
| Rival religious units | In a game on turn 53, 9 of the 49 visible rival units had a religion: 4 Islam and 3 Orthodoxy missionaries, and 2 Shinto apostles. They were the same units that a direct probe found on visible tiles, and the 40 other units had none |
| Religious strength | The player's four inquisitors had 75, and the visible rival missionaries 100 and apostles 110. Units with none had no field |
| A religious attack | An inquisitor next to an Islam missionary, whose owner wasn't at war with the player, attacked with the melee request. It took 19 damage and the missionary 46. The `attack` action refused it, and accepted it after the fix |
| City religion | The followers, both pressures, the pressure exerted, and the majority of 11 cities matched the raw calls. Noviodunum matched the screen: 8 followers, 26 a turn, 1,493 in all, and 2 exerted. The three converting cities matched the screen and the raw calls |
| `condemn_heretic` | A knight on the tile of a Shinto apostle of a player at war passed the check, and the request removed the apostle and left the knight with no moves |
| A spy on a mission | `awake` before, and `operation` right after a Gain Sources mission started |

Date checked: game files on 2026-11-06. Running game on Windows on 2026-11-06.
