# Game player overview

Status: open. The `player` section of `SentientSystems_GetState`, what the top bar shows about the player as a whole, is confirmed in a running game with Gathering Storm, with the file sent through the tuner. It matches the top bar. Later tasks add the Yields, Resources, City Status, and Era Progress screens here.

The calls the player section of the state uses. See [in-game-lua.md](../design/core/in-game-lua.md).

## Questions

1. Does the top bar show the same numbers without Gathering Storm, and with a `CAPABILITY_` turned off?

## What we know now

### Top bar

`TopPanel.lua` draws the bar. The Rise and Fall file, `TopPanel_Expansion1.lua`, only changes the bar's background for a golden or dark age, and the Gathering Storm file, `TopPanel_Expansion2.lua`, adds the favor button and the strategic stockpiles. Confirmed in files.

- **Science and culture.** `RefreshYields` shows `GetTechs():GetScienceYield()` and `GetCulture():GetCultureYield()` per turn, in the number format `{1: number +#,###.#;-#,###.#}`, which rounds to the nearest tenth. They were 123.50390625 and 216.62109375, and the bar showed +123.5 and +216.6. Confirmed in files and on Windows on 2026-10-29.
- **Faith.** `GetReligion():GetFaithBalance()` in the format `#,###.#`, and `GetFaithYield()` per turn. They were 2357.01 and 109, and the bar showed 2,357 and +109. Confirmed in files and on Windows on 2026-10-29.
- **Gold.** The balance is `GetTreasury():GetGoldBalance()` rounded down, and the income per turn is `GetGoldYield()` less `GetTotalMaintenance()`, so the upkeep is already taken off. They were 9610.84 and 475.08 less 210, and the bar showed 9,610 and +265. Confirmed in files and on Windows on 2026-10-29.
- **Tourism.** `GetStats():GetTourism()` rounded to a tenth. The bar hides it at 0. It was 92. Confirmed in files and on Windows on 2026-10-29.
- **Trade routes.** `RefreshTrade` shows `GetTrade():GetNumOutgoingRoutes()` over `GetOutgoingRouteCapacity()`, and hides the button when the capacity is 0. They were 17 and 20. Confirmed in files and on Windows on 2026-10-29.
- **Favor.** With Gathering Storm only, the override of `RefreshYields` shows `GetFavor()` and `GetFavorPerTurn()`, which a player has only with that expansion. They were 335 and +3. Confirmed in files and on Windows on 2026-10-29.
- **Envoys.** The bar's envoy counter reads `GetInfluence()`, which the `envoys` section holds, so the player section leaves it out. Confirmed in files.
- **Capabilities.** The bar skips a yield when its `CAPABILITY_` is off, such as `CAPABILITY_SCIENCE`. The state doesn't check them, so a game that turns one off still gets the key. Confirmed in files.

## Method

1. To read the player section before the `.modinfo` loads `SentientSystemsCore_StatePlayer.lua`, send the file with its comment lines removed, then `print(SentientSystems_EncodeJson(SentientSystems_GetPlayerState(Players[0])))`, as in [game-choices.md](game-choices.md#method), step 6.
2. Compare each value with the top bar.

## Results

A single-player game with Gathering Storm, in `SentientSystemsCore_UI`:

| Check | Result |
| --- | --- |
| The player section against the top bar | Science 123.5, culture 216.6, faith 2,357 and 109, gold 9,610 and 265.1, tourism 92, trade routes 17 of 20, favor 335 and 3. All matched the bar |

Date checked: game files and a running game on Windows on 2026-10-29.
