# City details in the state

Status: in progress. The city religion, and a rival city's, are confirmed in a running game with Gathering Storm. The room for a purchased unit is not yet checked.

The calls the city details in the state use, as the city banner and the Religion screen show them. The unit details are in [unit-details.md](unit-details.md). See [design/core/mod/state.md](../../design/core/mod/state.md).

## Questions

- What does the purchase room call return?

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

## Method

1. For the city religion, load `SentientSystemsCore_StateCities.lua` the same way, call `SentientSystems_GetCityStates(Players[0])`, and compare each city's `religion` with `city:GetReligion()`.
2. For a rival city's religion, load `SentientSystemsCore_StateCities.lua` and `SentientSystemsCore_StateRivals.lua`, and call `SentientSystems_GetRivalCityStates(0)`.

## Results

A single-player game with Gathering Storm, in `SentientSystemsCore_UI`:

| Check | Result |
| --- | --- |
| City religion | The followers, both pressures, the pressure exerted, and the majority of 11 cities matched the raw calls. Noviodunum matched the screen: 8 followers, 26 a turn, 1,493 in all, and 2 exerted. The three converting cities matched the screen and the raw calls |
| Rival city religion | Con Cuông matched the screen. 12 of 47 rival cities were converting, 2 of them from a majority |

Date checked: game files on 2026-11-06. Running game on Windows on 2026-11-06.
