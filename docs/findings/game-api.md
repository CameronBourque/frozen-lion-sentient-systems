# Game API

Status: open. Listing cities and units is confirmed in a running game. The rest is partly confirmed from game files. civ6-mcp's code covers more calls, unconfirmed.

This file lists the game calls the bridge needs, apart from the actions, which are in [game-actions.md](game-actions.md), with the Lua state (gameplay or UI) and where we found each call. "Confirmed in files" means the game's own Lua uses the call that way. "Tested" means we ran it from the tuner. "Used by civ6-mcp" means [civ6-mcp](https://github.com/lmwilki/civ6-mcp/tree/dd2019056371b92ea4854e879ddf05a8cad95e8a) calls it that way at commit `dd20190`, read on 2026-10-16. That code plays live games, but we haven't run the call ourselves, so it stays unconfirmed.

## Questions

1. Can a script write a game property that saves keep, for checkpoint IDs?
2. Can UI Lua dismiss the hotseat pass screen, so agent turns start without a click? Test in phase 2.

## What we know now

### Cities

```lua
for i, pCity in pPlayer:GetCities():Members() do
	-- pCity:GetName(), pCity:GetX(), pCity:GetY(), pCity:GetPopulation()
end
```

- The loop form is confirmed in files: `Base/Assets/UI/WorldView/DistrictPlotIconManager.lua`, line 101.
- `GetID()`, `GetName()`, `GetX()`, `GetY()`, and `GetPopulation()` work on each city in `GameCore_Tuner` and in `SentientSystemsCore_UI`. Both states returned the same city. The gate passed `GetName()` through `Locale.Lookup` where `Locale` exists, and both states printed the display name, `Aduatuca`. Not checked: whether `GameCore_Tuner` has `Locale`. Confirmed on Windows on 2026-10-23.
- civ6-mcp calls the same five functions, in [`build_cities_query`](https://github.com/lmwilki/civ6-mcp/blob/dd2019056371b92ea4854e879ddf05a8cad95e8a/src/civ_mcp/lua/cities.py#L16).

### Units

- `UnitManager.GetUnit(playerID, unitID)` returns one unit. The game's Lua uses it 41 times. Confirmed in files. It works in `SentientSystemsCore_UI` and in `InGame`. Confirmed on Windows on 2026-10-23.
- `pPlayer:GetUnits():Members()` lists units, in the same pattern as cities. `GetID()`, `GetType()`, `GetX()`, `GetY()`, and `GetMovesRemaining()` work on each unit in `SentientSystemsCore_UI`. `GameInfo.Units[unit:GetType()].UnitType` gives the type name, such as `UNIT_GAUL_GAESATAE`. Confirmed on Windows on 2026-10-23.
- civ6-mcp skips units whose X position is `-9999`, in [`build_units_query`](https://github.com/lmwilki/civ6-mcp/blob/dd2019056371b92ea4854e879ddf05a8cad95e8a/src/civ_mcp/lua/units.py#L23). Unconfirmed, used by civ6-mcp.
- `Players[playerID]:GetUnits():FindID(unitID)` returns one unit in `GameCore_Tuner`. Confirmed on Windows on 2026-10-23. civ6-mcp uses it there too, in [`lua/_helpers.py`](https://github.com/lmwilki/civ6-mcp/blob/dd2019056371b92ea4854e879ddf05a8cad95e8a/src/civ_mcp/lua/_helpers.py#L61).

### Turn number

`Game.GetCurrentGameTurn()` returns the turn number. It's in `Base/Assets/UI/ARXManager.lua` at line 253. Confirmed in files.

### Active player

`Game.GetLocalPlayer()` returns the human at the screen.

- In single player it returned 0, the one human, in `SentientSystemsCore_UI` through the tuner. A print from the turn event showed 0 on every turn, AI turns included.
- In hotseat with two humans it followed the human whose turn it was: 0 on player 0's turns and 1 on player 1's. It kept the last human's ID through the AI turns.
- In hotseat, `Events.LocalPlayerChanged` fired at each handover, before the pass screen and before the next human's `PlayerTurnActivated`. Its first argument is the new local player. Its second came through as `nil`.

Confirmed on Windows on 2026-10-22. The tuner is closed in hotseat, so the hotseat results come from a temporary print to `Lua.log`.

### Turn events

See [lua-contexts.md](lua-contexts.md). The gameplay event is `GameEvents.PlayerTurnStarted`. The UI events are `Events.PlayerTurnActivated` and `Events.LocalPlayerTurnBegin`.

### Game properties (for checkpoint IDs)

- `Game:SetProperty(key, value)` and `Game:GetProperty(key)` appear in `DLC/CivRoyaleScenario/Scripts/CivRoyaleScenario_StartScript.lua`, lines 158 and 173. That file is a gameplay script. Confirmed in files.
- Players have the same methods. `pPlayer:SetProperty` appears in `DLC/BlackDeathScenario/Scripts/BlackDeathScenario.lua`, line 373.
- Unconfirmed: whether the value survives a save and reload, and whether a UI script can call `SetProperty` or only `GetProperty`. Test both in phase 2.

### Mod metadata

- Official `.modinfo` files use a whole-number version, for example `<Mod id="..." version="1">` in `DLC/Australia/Australia.modinfo` and `DLC/Expansion2/Expansion2.modinfo`. Confirmed in files. Most workshop mods do too, but some use `1.2` or `4.2`.
- The game accepts `version="0.1.0"` on `<Mod>`. The mod lists in **Additional Content** and loads. A save made with `version="1"` loads after the change, and a save made with `version="0.1.0"` reloads. Confirmed on Windows on 2026-10-22.
- `Modding.GetModProperty(handle, "Version")` returns `<Properties><Version>`, not the `version` attribute. With the property set to `0.1.0-test`, it returned `0.1.0-test`. Get the handle from `Modding.GetActiveMods()`, whose entries have `Id` and `Handle` but no `Version` field. Confirmed in `InGame` on Windows on 2026-10-22.
- Gameplay states have no `Modding`. `type(Modding)` is `nil` in the core mod's gameplay state. Confirmed on Windows on 2026-10-22.
- The Gathering Storm mod ID is `4873eb62-8ccc-4574-b784-dda455e74e68` (`Expansion2`). Use it for a dependency or in criteria.

## Method

Run each step through the tuner, and record the Lua state you ran it in.

1. **List cities.** Use the [city loop](#cities) for `Game.GetLocalPlayer()`, and print `name, x, y, population` for each city. Run the loop in a gameplay state first, then in a UI state. Compare what each state sees.
2. **List units.** Loop over `Players[id]:GetUnits():Members()` and print `id, type, x, y, moves left`. You need a unit ID for the next step.
## Results

The bridge ran steps 1 and 2 in a single-player game, with one city and one unit.

| Call | Lua state | Result | Date |
| --- | --- | --- | --- |
| `Game.GetLocalPlayer()` | `SentientSystemsCore_UI` | `0` | 2026-10-23 |
| City loop | `GameCore_Tuner` | One city: ID `65536`, `Aduatuca`, at (42, 49), population 1 | 2026-10-23 |
| City loop | `SentientSystemsCore_UI` | The same city, with the same values | 2026-10-23 |
| Unit loop | `SentientSystemsCore_UI` | One unit: ID `131073`, `UNIT_GAUL_GAESATAE`, at (41, 49), 2 moves left | 2026-10-23 |

Date checked: game files on 2026-10-16 and 2026-10-23. Running game on Windows: mod metadata and the active player on 2026-10-22, and cities and units on 2026-10-23.

