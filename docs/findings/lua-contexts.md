# Lua states

Status: open. The state list, the `InGame` probe, how the list changes over a session, the core mod's own states, their Lua version and errors, and a move requested from the core mod's UI state are confirmed in a running game on Windows. The rest is partly confirmed from game files.

Civ VI runs Lua in separate states. Gameplay scripts and UI scripts have different APIs. The FireTuner state list shows which states exist in a running game.

## Questions

1. Can a UI state read data from a gameplay state, and the other way around? Through what: `ExposedMembers`, `LuaEvents`, or properties?
2. Can a mod run Lua in the front end, so that it can report when the player moves between the main menu, the setup screen, and a game?
3. Can Lua start a loaded game from the loading screen, in place of the player's click on its button? A tool that starts test presets needs this, because commands return nothing until after the click. See question 4.
4. Why did the tuner not answer `LSQ:` before the click in one load, when FireTuner listed the in-game states before the click in another? See [state lifecycle](#state-lifecycle).

## What we know now

### Two script types

| Script type | How a mod adds it | Example in the game files | Status |
| --- | --- | --- | --- |
| Gameplay script | `<AddGameplayScripts>` in `.modinfo` | `DLC/AlexanderScenario/AlexanderScenario.modinfo`, line 59 | Confirmed |
| UI script | `<AddUserInterfaces>` in `.modinfo`, with `<Context>InGame</Context>`. The action lists only the XML file, and the game loads the Lua file with the same name | `Base/Assets/UI/*.lua`, each with a matching `.xml` | Confirmed with the core mod on Windows, 2026-10-22 |

### Turn events differ by script type

| Event | Used in | Example | Status |
| --- | --- | --- | --- |
| `GameEvents.PlayerTurnStarted` | Gameplay scripts | `DLC/AlexanderScenario/Scripts/AlexanderScenario.lua`, line 247. The Poland, Vikings, and Indonesia–Khmer scenarios use it too | Confirmed |
| `Events.PlayerTurnActivated` | UI scripts | `Base/Assets/UI/Automation/Automation_ObserverCamera.lua`, line 560 | Confirmed |
| `Events.LocalPlayerTurnBegin` | UI scripts | `Base/Assets/UI/ActionPanel.lua`, line 1334 | Confirmed |

The base game UI uses `Events.*`, and scenario gameplay scripts use `GameEvents.*`. In single player on Windows on 2026-10-22, `GameEvents.PlayerTurnStarted` in a gameplay script and `Events.PlayerTurnActivated` in a UI script each fired once when the human's turn started, gameplay first. The `IsHuman()` filter in each handler kept AI turns out of the print. Neither fired when a save loaded. The first signal came when the player ended a turn and the next one started. In hotseat, a load does start the first human's turn: `Events.PlayerTurnActivated` fired for player 0 right after the pass screen, with no turn ended first.

Turns run one player at a time. An unfiltered print with the time, from `Events.PlayerTurnActivated` and `Events.PlayerTurnDeactivated`, showed this order each round. The humans went first, and each turn ended before the next started. Then every other player went in ID order, ending with 62 and 63. In `InGame`, `PlayerConfigurations[id]:GetCivilizationTypeName()` returned `CIVILIZATION_FREE_CITIES` for 62 and `CIVILIZATION_BARBARIAN` for 63. In these games, which were a few turns from a fresh start, each of those turns started and ended within a second, and all of them together took 2 to 3 s. AI turns get slower as a game goes on, because the AI has more to do. `IsTurnActive()` was true for each player inside its own activation event. Confirmed in single player and in hotseat on Windows on 2026-10-22, with about 30 players.

### Where actions can come from

The UI moves units with `UnitManager.RequestOperation` and ends turns with `UI.RequestAction`. See [game-api.md](game-api.md). These are request functions. The engine checks each action and applies it only if it is legal. The design requires this path. See [design/core/in-game-lua.md](../design/core/in-game-lua.md).

The core mod's own UI state has `UnitManager.RequestOperation` and `UI.RequestAction`. See [the core mod's states](#the-core-mods-states). A move requested there takes effect. The bridge sent `RequestOperation` to `SentientSystemsCore_UI`, the unit moved one tile on the map, and `GameCore_Tuner` read its new position 1 s later. Confirmed in single player on Windows on 2026-10-23. The calls are in [game-api.md](game-api.md#moving-a-unit).

The game's Lua files never call `UnitManager.MoveUnit`, so don't rely on it. Checked on 2026-10-16. Gameplay scenario scripts do use `UnitManager.InitUnit` and `UnitManager.PlaceUnit`, for example in `DLC/VikingsScenario/Scripts/VikingScenario.lua`.

### State names from other projects

Two community projects name the states they use. Both states appear in the [Windows state list](#lua-state-list). Their uses are unconfirmed on Windows. See [tuner-protocol.md](tuner-protocol.md#what-we-know-now) for the projects.

| State | Use | Source |
| --- | --- | --- |
| `GameCore_Tuner` | Read-only gameplay state. civ6-logger uses it for almost all reads | [civ6-logger ARCHITECTURE.md](https://github.com/PatrickJYKang/civ6-logger/blob/c21795250050447c89d42858afdf3decbac49bd8/docs/ARCHITECTURE.md), "Two ports, and which Lua state to use" |
| `InGame` | UI state. civ6-logger uses it for getters that `GameCore_Tuner` lacks, such as the current government. civ6-mcp sends its commands to it | civ6-logger, same section. [civ6-mcp README](https://github.com/lmwilki/civ6-mcp/tree/dd2019056371b92ea4854e879ddf05a8cad95e8a), "How it works" |

civ6-mcp sends commands to `InGame`, which matches the assumption that the action API runs in a UI state.

### The core mod's states

| Item | Value | Status |
| --- | --- | --- |
| State names | Each script gets its own state, named after its file. The UI script `SentientSystemsCore_UI.lua` runs in `SentientSystemsCore_UI`, and `ContextPtr:GetID()` returns that name. A gameplay script `SentientSystemsCore_Gameplay.lua` ran in `SentientSystemsCore_Gameplay`. The tuner list and `Lua.log` both use these names | Confirmed |
| Globals | Two files in one `AddGameplayScripts` action don't share globals. A global set in the first read as `nil` in the second | Confirmed |
| Shared files | A file listed in `ImportFiles` loads into a state with `include("SentientSystemsCore_Tag")`, the file name without its extension. It worked in a gameplay state and in a UI state. `include` finds a file by name among the imported files of every enabled mod, so a generic name such as `Version` can load another mod's file | Confirmed |
| Calls from the tuner | The tuner can call the mod's global functions, such as `SentientSystems_Print` and `SentientSystems_GetVersion`, in the mod's gameplay and UI states | Confirmed |
| Request functions | In `SentientSystemsCore_UI`, `type(UnitManager.RequestOperation)` and `type(UI.RequestAction)` are both `function` | Confirmed |
| Lua version | `_VERSION` in `SentientSystemsCore_UI` is `2013.2.0 r13768`, a Havok Script version | Confirmed |
| `debug` library | `type(debug)` in `SentientSystemsCore_UI` is `nil` | Confirmed |
| Errors in `pcall` | An error from `error("text")` or a runtime error, caught by `pcall` in `SentientSystemsCore_UI`, has a message with the error, then `stack traceback:` and one line for each call. Errors that reach the tuner have the same form. See [tuner-commands.md](tuner-commands.md#what-we-know-now). An error raised with a table, such as `error({})`, has no trace | Confirmed |
| Paths in errors | An error in a mod file names the file by its full path, such as `C:\Users\<name>\Documents\My Games\Sid Meier's Civilization VI\Mods\SentientSystemsCore\UI\SentientSystemsCore_UI.lua:38`. The path holds the user's name | Confirmed |

The first five rows were checked on Windows on 2026-10-22, and the last four on 2026-10-23.

### State list over a session

| Item | Value | Status |
| --- | --- | --- |
| In-game menus | Opening in-game menus, such as the tech tree and a city screen, doesn't change the state list. Each menu is one of the states that always exist | Confirmed |
| Quit to the main menu | The tuner socket stays open. The list becomes the 32 front-end states, such as `MainMenu`, `FrontEnd`, `Lobby`, and `StagingRoom`. `Main State` stays 0 and `DebugHotloadCache` stays 1 | Confirmed |
| A command to a state that's gone | The tag 3 reply is `ERR:Invalid Lua State`, and no output comes back | Confirmed |
| Loading a game | The tuner doesn't answer `LSQ:` while the game loads. `Lua.log` prints `LoadScreen: OnLoadGameViewStateDone` when the loading screen shows its button. In FireTuner, the in-game states were listed from then on, but commands to the core mod's states returned no output and no error until the player clicked the button. In one load watched with `watch-states`, `LSQ:` got no reply before the click, and the socket reset at the click. See question 4 | Confirmed, except question 4 |
| Indexes after a load | After a reload of the same save, all 122 in-game states other than `Main State` and `DebugHotloadCache` had their old indexes | Confirmed, one load |
| Live reload | Editing the core mod's UI Lua file while a game runs rebuilds that UI context, and its load line prints again. This works in single player and in hotseat. Editing the gameplay Lua file doesn't reload it. Not measured: the delay, whether it needs `EnableTuner 1`, and what the reload resets | Confirmed, 2026-10-22 |
| `ContextPtr:GetID()` | Returns the state's name in a UI state: `InGame` in `InGame`, and `PlotInfo` in `PlotInfo`. `Main State` has no `ContextPtr` | Confirmed |

## Method

1. Connect FireTuner to a running game and copy the full state list here.
2. Run the same probe in each relevant state:

   ```lua
   print(type(UnitManager.RequestOperation), type(UI), type(UI and UI.RequestAction), type(Game.GetLocalPlayer))
   ```

3. Load the core mod and check which new states appear.
4. Close FireTuner, and run `npm run watch-states --workspace packages/core/bridge`. Open a few in-game menus. Save, quit to the main menu, and load the save. Click the loading screen's button to start the game, then stop the script.
5. To answer question 4, load a save and wait at the loading screen's button without clicking it. Check whether the client lists the in-game states. Do it four times: with `watch-states` and with FireTuner, each with the core mod off and on.
6. To check the Lua version and errors, run these in `SentientSystemsCore_UI`:

   ```lua
   print(_VERSION, type(debug))
   SentientSystems_CatchErrors("Probe", function() error("test") end)()
   SentientSystems_CatchErrors("Probe", function() error({}) end)()
   ```

## Results

### Lua state list

FireTuner listed 124 states in a Duel game with Gathering Storm rules, sorted by name in the state dropdown. `SaveGameMenu` appears twice. FireTuner opens in `Main State`. The main menu shows a different, shorter set of states. After a return to the main menu and a reload of the save, the in-game list came back. civ6-logger reports about 98 states, so the count depends on the platform, the ruleset, or the game. Captured on 2026-10-19:

`ActionPanel`, `AdvisorPopup`, `ARXManager`, `Automation_NarrationPopup`, `BoostUnlockedPopup`, `CameraManager`, `ChatPanel`, `ChooseArtifact`, `CityBannerManager`, `CityPanel`, `CityPanelCulture`, `CityPanelOverview`, `CityPanelPower`, `CityStates`, `CivicsChooser`, `CivicsTree`, `CivilopediaScreen`, `ClimateScreen`, `ConfirmKick`, `DebugHotloadCache`, `DeclareWarPopup`, `DedicationPopup`, `DiplomacyActionView`, `DiplomacyDealView`, `DiplomacyRibbon`, `DisloyalCityChooser`, `DistrictPlotIconManager`, `EdgeScroll`, `EndGameMenu`, `EraCompletePopup`, `EraProgressPanel`, `EraReviewPopup`, `EspionageChooser`, `EspionageEscape`, `EspionageOverview`, `EspionagePopup`, `EventPopup`, `ExpansionIntro`, `FullscreenMapPopup`, `GameCore_Tuner`, `GenVFX`, `GlobalResourcePopup`, `GovernmentScreen`, `GovernorAssignmentChooser`, `GovernorDetailsPanel`, `GovernorPanel`, `GreatPeoplePopup`, `GreatWorkShowcase`, `GreatWorksOverview`, `HistoricMoments`, `HotSeatBackground`, `InGame`, `InGamePopup`, `InGameTopOptionsMenu`, `InvitePopup`, `LaunchBar`, `LeaderScene`, `LoadGameMenu`, `Main State`, `MapLabelManager`, `MapPinListPanel`, `MapPinManager`, `MapPinPopup`, `MapSearchPanel`, `MinimapPanel`, `ModalLensPanel`, `MultiplayerTurnManager`, `NaturalDisasterPopup`, `NaturalWonderPopup`, `NewTurnPanel`, `NotificationPanel`, `Options`, `PantheonChooser`, `PartialScreenHooks`, `PausePanel`, `PBCNotificationPopup`, `PlayerChange`, `PlotInfo`, `PlotToolTip`, `PowerLensManager`, `ProductionManager`, `ProductionPanel`, `ProjectBuiltPopup`, `RazeCity`, `ReligionScreen`, `ReportScreen`, `ReportsList`, `ResearchChooser`, `RockBandMoviePopup`, `RockBandPopup`, `SaveGameMenu`, `SelectedUnit`, `SettlerInfluenceIconManager`, `SettlerWarningIconManager`, `StatusMessagePanel`, `StrategicView`, `SwitchLayoutPopup`, `TechCivicCompletedPopup`, `TechTree`, `TopPanel`, `TourismBannerManager`, `TradeOriginChooser`, `TradeOverview`, `TradeRouteChooser`, `TutorialGoals`, `TutorialUIRoot`, `TutorialWorldAnchor`, `UnitCaptured`, `UnitFlagManager`, `UnitPanel`, `UnitPromotionPopup`, `WonderBuiltPopup`, `WorldCongress`, `WorldCongressBetweenTurns`, `WorldCongressIntro`, `WorldCongressPopup`, `WorldCrisisPopup`, `WorldCrisisTracker`, `WorldInput`, `WorldRankings`, `WorldTracker`, `WorldViewIconsManager`, `WorldViewPlotMessages`

### State lifecycle

`watch-states` listed the states every 5 s on Windows on 2026-10-21, in the same game.

| Time | What the player did | What the script saw |
| --- | --- | --- |
| 15:23:31 | Nothing yet | 124 states, `InGame` at 119. The three `ContextPtr:GetID()` checks gave `no ContextPtr`, `InGame`, and `PlotInfo` |
| 15:23:31 to 15:25:56 | Opened in-game menus | No change |
| 15:25:56 | Quit to the main menu | 32 states, with no `InGame`. `print("still here")` sent to index 119 got `ERR:Invalid Lua State` |
| 15:26:52 to 15:27:42 | Loaded the save, and waited at the loading screen's button | No reply to `LSQ:` in 5 s, six times |
| 15:27:48 | Clicked the button | The socket reset with `ECONNRESET`. The script reconnected at once, and one more `LSQ:` got no reply |
| 15:27:57 | Nothing | 124 states, `InGame` at 119, and every in-game state at its old index |

The script's output showed up late, so the times in the table may lag the player's actions by an unknown amount.

Later loads on 2026-10-22, watched in FireTuner with the core mod on, disagree with this table. FireTuner's state list showed the in-game states, `SentientSystemsCore_UI` among them, while the loading screen still showed its button. `Lua.log` shows the core mod's UI context loading before `LoadScreen: OnLoadGameViewStateDone`. `SentientSystems_Print` sent to the mod's states before the click printed nothing and returned no error. After the click, the same call printed in both states. Two things differ between the loads: the client, which was the script or FireTuner, and the core mod, which was off or on. `watch-states` needs FireTuner closed, because the game takes one client at a time. See [tuner-protocol.md](tuner-protocol.md#what-we-know-now).

The main menu's 32 states are `Main State`, `DebugHotloadCache`, `Options`, `CreditsScreen`, `My2K`, `LoadGameMenu` three times, `PBCNotifyRemind`, `Lobby`, `Mods`, `SaveGameMenu` twice, `MultiSelectWindow`, `CityStatePicker`, `LeaderPicker`, `HostGame`, `ConfirmKick`, `EditHotseatPlayer`, `StagingRoom`, `FrontEndPopup`, `CivRoyaleIntro`, `PiratesIntro`, `CrossPlayLogin`, `MainMenu`, `StateTransition`, `JoiningRoom`, `UserSetupWarning`, `SwitchLayoutPopup`, `Test`, `FrontEnd`, and `InvitePopup`.

### API probe by state

| State | `RequestOperation` | `UI` | `UI.RequestAction` | `Game.GetLocalPlayer` |
| --- | --- | --- | --- | --- |
| `InGame` | `function` | `table` | `function` | `function` |
| `SentientSystemsCore_UI` | `function` | Not checked | `function` | Not checked |

Date checked: game files on 2026-10-16. Running game on Windows: 2026-10-22, and the move, the Lua version, and the errors from the core mod's UI state on 2026-10-23.
