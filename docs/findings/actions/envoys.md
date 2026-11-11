# Envoy action

Status: confirmed. Sending envoys to a city-state is confirmed in a running game with Gathering Storm, with the file sent through the tuner.

The game call that the envoy action wraps, with the Lua state it runs in and what the game checks. The city-states the player can send envoys to are in [choices/city-states.md](../choices/city-states.md).

The core mod's result format is in [design/core/mod/actions/README.md](../../design/core/mod/actions/README.md). The other actions are in the [actions index](README.md).

## Questions

None open.

## What we know now

### Request

`OnConfirmPlacement` in `Base/Assets/UI/PartialScreens/CityStates.lua`, lines 748 to 772, sends `UI.RequestPlayerOperation(Game.GetLocalPlayer(), PlayerOperations.GIVE_INFLUENCE_TOKEN, parameters)` once for each envoy placed.

The parameters hold the city-state's player ID in `PARAM_PLAYER_ONE`. Confirmed in files.

### What the game takes

`UI.CanStartPlayerOperation(playerID, PlayerOperations.GIVE_INFLUENCE_TOKEN, parameters, false)` returned `true` for a city-state the player hadn't met, and for the Free Cities, which can't receive envoys.

So the action checks the screen's rules itself, with `CanGiveTokensToPlayer` as in [choices/city-states.md](../choices/city-states.md). Confirmed on Windows on 2026-11-10.

### What the requests do

1.5 seconds after the requests, in `SentientSystemsCore_UI`, the city-state's `GetTokensReceived(playerID)` had gone up by the envoys sent, and the player's `GetTokensToGive()` down by the same. Confirmed on Windows on 2026-11-10.

### Blocker

The requests don't touch `IsGivingTokensConsidered()` on the player's influence. With every envoy spent it stayed `true`.

`ChangeTokensToGive(3)` from the tuner set it to `false`. With 1 envoy left after the action, it was still `false`, so `ENDTURN_BLOCKING_GIVE_INFLUENCE_TOKEN` stays up until the player spends the rest or the screen's `Close` sets it. Confirmed on Windows on 2026-11-10.

## Method

1. Send `Scripts/Actions/SentientSystemsCore_ActionsEnvoys.lua` to `SentientSystemsCore_UI`, as in [choices/production.md](../choices/production.md#method), step 4.
2. To get envoys, follow [choices/city-states.md](../choices/city-states.md#method), step 3.
3. Call `sendEnvoys` from the bridge. Wait 1.5 seconds, then read the player's `GetTokensToGive()` and `IsGivingTokensConsidered()` on `Players[0]:GetInfluence()`, and each city-state's `GetInfluence():GetTokensReceived(0)`.

## Results

A single-player game with Gathering Storm, on Rome's save with 10 city-states met, none at war, and the Free Cities at war.

With 2 envoys:

| Call | Result |
| --- | --- |
| `sendEnvoys(27, 1)`, Valletta | `{"ok":true}`. Valletta went from 1 envoy to 2, and 1 envoy was left |
| `sendEnvoys(29, 1)`, Mogadishu | `{"ok":true}`. Mogadishu went from 0 envoys to 1, and none were left |
| `sendEnvoys(27, 1)`, after that | `You have no envoys to send. The envoys choice lists city-states once you do.` |

After 3 envoys from the tuner:

| Call | Result |
| --- | --- |
| `sendEnvoys(21, 1)`, Auckland, unmet | `You haven't met city-state 21. Use an ID from the envoys choice.` |
| `sendEnvoys(62, 1)`, the Free Cities | `Player 62 isn't a city-state. Use an ID from the envoys choice.` |
| `sendEnvoys(27, 4)` | `You have 3 envoys to send, not 4.` |
| `SentientSystems_SendEnvoys(0, 27, 0)` | `Send a whole number of envoys, at least 1, not 0.` |
| `sendEnvoys(27, 2)` | `{"ok":true}`. Valletta went from 2 envoys to 4, and 1 envoy was left |

Date checked: game files on 2026-11-10. Running game on Windows on 2026-11-10.
