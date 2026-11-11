# City fate action

Status: open. Keeping a disloyal city, razing a captured one, and liberating a captured one to its founder are confirmed in a running game with Gathering Storm, with the files sent through the tuner.

Refusing a disloyal city, keeping a captured one, and liberating to the previous owner are confirmed only in files.

The game call that the city fate action wraps, with the Lua state it runs in and what the game checks. The options each screen offers are in [choices/city-fate.md](../choices/city-fate.md).

The core mod's result format is in [design/core/mod/actions/README.md](../../design/core/mod/actions/README.md). The other actions are in the [actions index](README.md).

## Questions

1. When does the raze screen offer `LIBERATE_PREVIOUS_OWNER`? After each capture, `GetOwnerBeforeOccupation()` read the capturing player, so the option didn't show.

## What we know now

### Request

The raze screen and the disloyal city screen send the same request for each button: `CityManager.RequestCommand(city, CityCommandTypes.DESTROY, params)`, with the directive in `params[UnitOperationTypes.PARAM_FLAGS]`. See [choices/city-fate.md](../choices/city-fate.md#raze-screen). Confirmed in files.

`CityManager.CanStartCommand` takes both liberate directives for a city whose raze screen hides them, so the action checks the screen's options instead, from `SentientSystems_GetCityFates`. Confirmed on Windows on 2026-10-26.

### What the request does

The request runs in `SentientSystemsCore_UI`. Within 2 seconds:

- **Keep a disloyal city.** The city was the player's, `ENDTURN_BLOCKING_CONSIDER_DISLOYAL_CITY` was gone, and the choice was empty.
- **Raze a captured city of population 1.** The city was gone at once, `ENDTURN_BLOCKING_CONSIDER_RAZE_CITY` was gone, and the choice was empty.
- **Liberate a captured city to its founder.** The founder owned the city, `ENDTURN_BLOCKING_CONSIDER_RAZE_CITY` was gone, and the choice was empty. A founder with no city left came back into the game.

Confirmed on Windows on 2026-11-11.

### Previous owner

Right after a capture, `GetOwnerBeforeOccupation()` returned the capturing player, 0, for a city taken from a major player and for one taken from the Free Cities. The city's owner before the capture was in `GetJustConqueredFrom()`.

The raze screen offers `LIBERATE_PREVIOUS_OWNER` only when the player can liberate to `GetOwnerBeforeOccupation()` and it isn't `GetJustConqueredFrom()`, so neither capture offered it. Confirmed on Windows on 2026-11-11.

## Method

1. Send `Scripts/SentientSystemsCore_CityFate.lua`, the choice file, `Scripts/Choices/SentientSystemsCore_Choices.lua`, and `Scripts/Actions/SentientSystemsCore_ActionsCityFate.lua` to `SentientSystemsCore_UI`, each without its comments and `include` lines, as in [choices/production.md](../choices/production.md#method), step 4.
2. For a disloyal city, load a save where a city has rebelled to join the player. Call `decideCity` from the bridge, wait 2 seconds, and read the blockers and the choice.
3. For a captured city, in `GameCore_Tuner`, send `Players[0]:GetDiplomacy():DeclareWarOn(owner, WarTypes.FORMAL_WAR, true)`, then capture the city as in [choices/city-fate.md](../choices/city-fate.md#method), step 2. Call `decideCity` as in step 2.

## Results

A single-player game with Gathering Storm, on turn 202, in `SentientSystemsCore_UI`.

Mbanza Kongo, city 655369, which rebelled to join the player, with `KEEP` and `REJECT`:

| Call | Result |
| --- | --- |
| `decideCity` with `RAZE` | `RAZE isn't an option for Mbanza Kongo. Use one of KEEP, REJECT.` |
| `decideCity` with city 65536 | `City 65536 isn't waiting for a decision. Use a city from the cityFates choice: 655369.` |
| `decideCity` with `KEEP` | `{"ok":true}`. The blocker cleared, and the city was the player's |
| `SentientSystems_DecideCity` with `KEEP` again | `You have no city to decide. The cityFates choice lists one once you capture a city or one rebels to join you.` |

Valletta, the only city of the city-state, captured by a Giant Death Robot as city 720906, with `KEEP` and `RAZE`:

| Call | Result |
| --- | --- |
| `decideCity` with `REJECT` | `REJECT isn't an option for Valletta. Use one of KEEP, RAZE.` |
| `decideCity` with `LIBERATE_FOUNDER` | `LIBERATE_FOUNDER isn't an option for Valletta. Use one of KEEP, RAZE.` |
| `decideCity` with `RAZE` | `{"ok":true}`. The blocker cleared, and the city was gone |

A later save, at war with the owners of Hong Kong and Brussels, each taken by a Giant Death Robot.

Hong Kong, city 917517, taken from player 10, who had taken it from its founder, the city-state Hong Kong, player 24. It offered `LIBERATE_FOUNDER` to player 24, `KEEP`, and a blocked `RAZE`:

| Call | Result |
| --- | --- |
| `decideCity` with `RAZE` | `You cannot raze a major civilization's original capital or a city that you or an ally founded or owned at the start of this war.` |
| `decideCity` with `LIBERATE_PREVIOUS_OWNER` | `LIBERATE_PREVIOUS_OWNER isn't an option for Hong Kong. Use one of LIBERATE_FOUNDER, KEEP, RAZE.` |
| `decideCity` with `LIBERATE_FOUNDER` | `{"ok":true}`. The blocker cleared, and player 24 owned Hong Kong |

The reason for `LIBERATE_PREVIOUS_OWNER` listed the blocked `RAZE`. The action now leaves blocked options out of that list.

Brussels, city 983053, taken from the Free Cities, player 62. Its founder, the city-state Brussels, player 18, had no city and wasn't alive. It offered `LIBERATE_FOUNDER` to player 18, `KEEP` with no grievances, and `RAZE`:

| Call | Result |
| --- | --- |
| `decideCity` with `LIBERATE_FOUNDER` | `{"ok":true}`. The blocker cleared, and player 18 was alive with Brussels as its one city |

The saves were only test saves. In the first, the player is at war with Valletta's city-state, which no longer has a city, and has a Giant Death Robot next to where it stood.

Date checked: game files on 2026-10-26. Running game on Windows on 2026-11-11.
