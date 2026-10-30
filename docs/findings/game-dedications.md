# Game dedications

Status: open. The `dedications` key of `SentientSystems_GetChoices`, the dedications the player may make for the era that began, is confirmed in a running game with Gathering Storm and matches the dedication popup, for a golden, a dark, a heroic, and a normal age.

The calls the dedication choice uses, as the dedication popup shows them. The other choices are in [game-choices.md](game-choices.md). See [in-game-lua.md](../design/core/in-game-lua.md).

## Questions

None open.

## What we know now

### Dedication popup

`DLC/Expansion2/UI/Additions/DedicationPopup.lua` draws the dedication popup, as Expansion1's copy does. `EraReviewPopup.lua` opens it, from `LuaEvents.EraReviewPopup_MakeDedication` when the player presses **Continue**, and `NotificationPanel_Expansion1.lua` shows the review from the `ENDTURN_BLOCKING_COMMEMORATION_AVAILABLE` notification. Confirmed in files.

- **Age.** `OnGameEraChanged`, lines 25 to 120, reads `Game.GetEras()`: `HasHeroicGoldenAge` first, then `HasGoldenAge`, then `HasDarkAge`, otherwise normal. A heroic age is also a golden one for `HasGoldenAge`, so it shows the golden text. A heroic age follows a dark one, and the player needs a golden age in the era after it. Confirmed in files and on Windows on 2026-10-28.
- **Era.** The title names the era that began, `GameInfo.Eras[Game.GetEras():GetCurrentEra()].Name`, such as "Make your dedication for the Classical Era". Confirmed in files and on Windows on 2026-10-28.
- **Options.** `GetPlayerCommemorateChoices(playerID)` returns indexes in `GameInfo.CommemorationTypes`, four in each age checked: Free Inquiry, `COMMEMORATION_SCIENTIFIC`, Pen, Brush, and Voice, `COMMEMORATION_CULTURAL`, Monumentality, `COMMEMORATION_INFRASTRUCTURE`, and Exodus of the Evangelists, `COMMEMORATION_RELIGIOUS`. The name is the row's `CategoryDescription`, such as `LOC_MOMENT_CATEGORY_SCIENTIFIC`, which reads "Free Inquiry". Confirmed in files and on Windows on 2026-10-28.
- **Picks.** `GetPlayerNumAllowedCommemorations(playerID)` is how many the player must choose: 1 in a golden and a dark age, and 3 in a heroic age. **Confirm** works only when the player has chosen that many. The popup banner says "You may make three dedications". Confirmed in files and on Windows on 2026-10-28.
- **Text.** In a golden age the popup shows the row's `GoldenAgeBonusDescription`, with `NormalAgeBonusDescription` after it when `IsPlayerAlwaysAllowedCommemorationQuest(playerID)` is true, which it was not. A dark age shows `DarkAgeBonusDescription`, and any other age `NormalAgeBonusDescription`. The golden text names the age's bonus, such as "Eurekas provide an additional 10% of technology costs", and the dark and normal texts name the era score the dedication gives, which were the same for each option in the dark age checked. The texts hold game markup, such as `[NEWLINE]` and `[ICON_TechBoosted]`. Confirmed in files and on Windows on 2026-10-28.
- **Choosing.** Each pick sends `PlayerOperations.COMMEMORATE` with `PARAM_COMMEMORATION_TYPE` set to the row's index, once for each pick. Confirmed in files.
- **Blocker first.** The choice reads the era's choices only while `ENDTURN_BLOCKING_COMMEMORATION_AVAILABLE` is up, as the popup does, because a `GetNext` call with nothing waiting crashed the game for spies. See [game-spies.md](game-spies.md). Confirmed in files.

## Method

1. To end an era on a game with `EnableTuner 1`, send `Game.SetCurrentGameTurn(n)` through `GameCore_Tuner`, with `n` one turn before the era's latest end turn, from `Game.GetEras():GetCurrentEraMaximumEndTurn()`, then end the turn. The game starts its 10-turn countdown, `GetNextEraCountdown()`. A second jump 9 turns on, then another end turn, changes the era. The game and the UI state disagree about the turn until the next end turn.
2. To choose the age, change the era score with `Game.GetEras():ChangePlayerEraScore(0, n)` in `GameCore_Tuner`, before the era ends, against `GetPlayerGoldenAgeThreshold(0)` and `GetPlayerDarkAgeThreshold(0)`. A dark age needs a score below the dark threshold. Then raise the score above the golden threshold in the era after it for a heroic age.

## Results

A single-player game with Gathering Storm, on turns 190 to 380 and 198, in `SentientSystemsCore_UI`:

| Check | Result |
| --- | --- |
| The choice in a golden age, at the Classical Era | `age` golden, `picks` 1, four options with the golden text. The popup showed "Because you earned a golden age, you may make one dedication" and the same four names and texts |
| The same in a dark age, with the score under the threshold | `age` dark, `picks` 1, four options with the dark text. The popup showed "Because you earned a dark age, you may make one dedication" and "Dedication Bonus" texts |
| The same in a normal age, with the score between the thresholds | `age` normal, `picks` 1, four options with the normal text. The popup showed "Because you earned a normal age, you may make one dedication" and the same names and texts. Read through the bridge's `readChoices`, which parsed it |
| The same in a heroic age, at the Medieval Era | `age` heroic, `picks` 3, four options with the golden text, with the percent sign as `\u0025`. The popup showed "Because you earned a heroic age, you may make three dedications" |

Date checked: game files on 2026-10-28. Running game on Windows on 2026-10-28.
