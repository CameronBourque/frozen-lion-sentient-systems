# Era progress

Status: confirmed. The Era Progress panel's `era` is confirmed in a running game with Gathering Storm against its screenshot.

The calls the era section of the state uses, as the Era Progress panel shows them. See [design/core/mod/state.md](../../design/core/mod/state.md).

## Questions

None open.

## What we know now

### Era Progress panel

`DLC/Expansion1/UI/Additions/EraProgressPanel.lua` and the Gathering Storm copy are identical, with `EraSupport.lua` for the threshold tooltips. The base game has no ages. Confirmed in files.

- **Era, score, and age.** `Game.GetEras():GetCurrentEra()` indexes `GameInfo.Eras`, `GetPlayerCurrentScore(player)` is the score, and the age is heroic, golden, dark, or normal from `HasHeroicGoldenAge`, `HasGoldenAge`, and `HasDarkAge`, in that order.

  The save was in the Renaissance Era with 200 points and a normal age. Confirmed on Windows on 2026-10-29.
- **Thresholds.** `GetPlayerDarkAgeThreshold` and `GetPlayerGoldenAgeThreshold` were 228 and 239, which the panel shows as Dark 0 - 227, Normal 228 - 238, and Golden 239+, with the check on the age the score earns: golden at the golden threshold, normal at the dark one, dark below.

  The panel hides the normal line with `CAPABILITY_DRAMATICAGES`, and all the thresholds in the final era, where `GetCurrentEra() == GetFinalEra()`. Its tooltips list the baseline and sources of each threshold, which the state leaves out. Confirmed on Windows on 2026-10-29.
- **Turns until the next era.** With the countdown started, `GetNextEraCountdown() + 1`. Before it, from `GetCurrentEraMinimumEndTurn()` less the turn, which is at least `GlobalParameters.NEXT_ERA_TURN_COUNTDOWN`, and `GetCurrentEraMaximumEndTurn()` less the turn, which is at least 0.

  On turn 85 the ends were 101 and 111 and the countdown 10, so 16 - 26, as the panel showed. Confirmed on Windows on 2026-10-29.
- **Effects.** The age's text takes `GetCivilianLoyalty()`, the loyalty pressure each citizen exerts, which was 1, and each of `GetPlayerActiveCommemorations` adds its bonus text for the age, which is the same text rule as the dedication popup's.

  The Coinage dedication was active. The age's own text is left out, as `age` has it. Confirmed on Windows on 2026-10-29.
- **Score breakdown and other players.** `GetPlayerPreviousEraScoreBreakdown` and `GetPlayerCurrentEraScoreBreakdown` return lists of tables of a source's text to its points, 36 for the earlier eras, and 6 and 1 for this one, which the panel computes and doesn't show.

  The icons are the met players in the order heroic, golden, normal, dark, then the unmet ones with no age. All 11 of the other players were met, 1 heroic, 1 golden, 3 normal, and 6 dark. Confirmed on Windows on 2026-10-29.

## Method

1. For the Era Progress panel, send `SentientSystemsCore_Eras.lua` and `SentientSystemsCore_StatePlayerEra.lua` without their comment and include lines, then `print(SentientSystems_EncodeJson(SentientSystems_GetEraState(Players[0])))`, and compare with the panel.

## Results

A single-player game with Gathering Storm, in `SentientSystemsCore_UI`:

| Check | Result |
| --- | --- |
| The Era Progress panel on the same save, through the bridge's reader | `ERA` parsed. Renaissance Era, score 200, normal age, dark next, thresholds 228 and 239, 16 - 26 turns, the Coinage dedication, and 11 other players, as the panel showed |

Date checked: game files and a running game on Windows on 2026-10-29.
