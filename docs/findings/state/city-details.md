# City details in the state

Status: confirmed. The city religion, a rival city's, and the city power are confirmed in a running game with Gathering Storm. The room for a purchased unit is not a state field, and is confirmed for every kind of unit.

The calls the city details in the state use, as the city banner, the Religion screen, and the Power tab show them. The unit details are in [unit-details.md](unit-details.md). See [design/core/mod/state.md](../../design/core/mod/state.md).

## Questions

None open.

## What we know now

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

The banner shows the same values for a rival city on a revealed tile, and the rivals section has them too, from the same function. Con Cuông, a city of Vietnam, showed Taoism as its majority, converting to Shinto in 155 turns, as the screen showed.

A city can also convert from neutral, such as Rotterdam to Protestantism in 4 turns.

All 11 cities of the player came to 3,386 bytes once three religions had spread, about 310 for each, so the religion is part of the cities section.

The 47 rival cities on revealed tiles came to 10,974 bytes of religion, about 230 each, in 19,347 bytes for the rival cities. 12 of them were converting and 2 had a majority they would lose.

### City power

The Power tab of the city panel, `DLC/Expansion2/UI/Additions/CityPanelPower.lua`, shows a city's power with Gathering Storm. Confirmed in files and in a running game.

- **The call.** `city:GetPower()` returns an object, or `nil` without Gathering Storm, as the panel checks at line 36.
- **Usable and required.** `GetFreePower()` and `GetTemporaryPower()` together are the usable power, "2 Usable of 7 Required" for Avaricum, and `GetRequiredPower()` is the required power.

  The panel shows the usable power as the required power when `IsFullyPoweredByActiveProject()` is `true`, at line 54.
- **Status.** The panel shows "no power needed" at 0 required, "unpowered" when `IsFullyPowered()` is `false`, and "powered" otherwise. Avaricum was unpowered, Bibrax powered, and Lisieux needed none.
- **Sources.** `GetFreePowerSources()` and `GetTemporaryPowerSources()` list what gives the city power, `GetRequiredPowerSources()` what needs it, and `GetGeneratedPowerSources()` what it generates for others. Each entry is a table with one key, the text of the source, and its power as the value.

  Avaricum had Solar 2, and needed Factory 2, Stock Exchange 3, Food Market 1, and Airport 1. Cenabum had Solar 6 and Wind 2 and needed none.

  The panel rounds each value to one decimal place, as the state does.
- **Effect.** An underpowered city's buildings with a power load are temporarily less effective, as the panel's description says. A Stock Exchange gives 7 more gold when powered, from its tooltip.

The power of the player's 13 cities came to 1,853 bytes, about 140 for each. The state has the player's own cities only.

### Room for a purchased unit

The room isn't in the state. The game's purchase check already answers it for each kind of unit, because a purchased unit appears on a tile that depends on its kind.

A military unit appears in the encampment and then the city center, a ship in the harbor and then the city center, and a religious unit in the holy site and then the city center. A civilian or support unit appears in the city center.

An air unit appears in the aerodrome, which holds 4 aircraft, and a full one gives its own reason.

A city with room for one kind can have none for another, so a field for the city would be wrong for most units. Each purchase option carries the game's reason instead, `Too many units of the same class in this location.`. See [choices/purchases.md](../choices/purchases.md#room-for-a-unit).

## Method

1. For the city religion, load `SentientSystemsCore_StateCities.lua` the same way, call `SentientSystems_GetCityStates(Players[0])`, and compare each city's `religion` with `city:GetReligion()`.
2. For a rival city's religion, load `SentientSystemsCore_StateCities.lua` and `SentientSystemsCore_StateRivals.lua`, and call `SentientSystems_GetRivalCityStates(0)`.
3. For the power, load `SentientSystemsCore_StateCities.lua` the same way, and compare each city's `power` with the Power tab of the city panel, opened with its lightning bolt button.

## Results

A single-player game with Gathering Storm, in `SentientSystemsCore_UI`:

| Check | Result |
| --- | --- |
| City religion | The followers, both pressures, the pressure exerted, and the majority of 11 cities matched the raw calls. Noviodunum matched the screen: 8 followers, 26 a turn, 1,493 in all, and 2 exerted. The three converting cities matched the screen and the raw calls |
| Rival city religion | Con Cuông matched the screen. 12 of 47 rival cities were converting, 2 of them from a majority |
| City power | Avaricum matched the panel: 2 usable of 7 required, unpowered, with Solar 2 and Factory 2, Stock Exchange 3, Food Market 1, and Airport 1 required. Bibrax had 6 of 6 from Hydroelectric and was powered, and Cenabum had Solar 6 and Wind 2 and needed none |

Date checked: game files on 2026-11-06. Running game on Windows on 2026-11-06.
