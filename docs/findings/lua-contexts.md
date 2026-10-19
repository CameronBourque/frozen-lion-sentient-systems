# Lua states

Status: open. The state list and the `InGame` probe are confirmed in a running game on Windows. The rest is partly confirmed from game files.

Civ VI runs Lua in separate states. Gameplay scripts and UI scripts have different APIs. The FireTuner state list shows which states exist in a running game.

## Questions

1. Which state can issue player actions through the UI's request functions?
2. Can a UI state read data from a gameplay state, and the other way around? Through what: `ExposedMembers`, `LuaEvents`, or properties?
3. Do the core mod's own states show in the tuner list under predictable names, and can the tuner call the mod's global functions in them?
4. Which state fires the turn-start event reliably for each human slot, including in hotseat?
5. Does a UI state see globals from `Version.lua`, or does it need its own `include`?

## What we know now

### Two script types

| Script type | How a mod adds it | Example in the game files | Status |
| --- | --- | --- | --- |
| Gameplay script | `<AddGameplayScripts>` in `.modinfo` | `DLC/AlexanderScenario/AlexanderScenario.modinfo`, line 59 | Confirmed |
| UI script | `<AddUserInterfaces>` in `.modinfo`, with a Lua file and an XML file | `Base/Assets/UI/*.lua`, each with a matching `.xml` | The files are confirmed. The `.modinfo` action is unconfirmed |

### Turn events differ by script type

| Event | Used in | Example | Status |
| --- | --- | --- | --- |
| `GameEvents.PlayerTurnStarted` | Gameplay scripts | `DLC/AlexanderScenario/Scripts/AlexanderScenario.lua`, line 247. The Poland, Vikings, and Indonesia–Khmer scenarios use it too | Confirmed |
| `Events.PlayerTurnActivated` | UI scripts | `Base/Assets/UI/Automation/Automation_ObserverCamera.lua`, line 560 | Confirmed |
| `Events.LocalPlayerTurnBegin` | UI scripts | `Base/Assets/UI/ActionPanel.lua`, line 1334 | Confirmed |

The base game UI uses `Events.*`, and scenario gameplay scripts use `GameEvents.*`. The core mod's turn signal should use the event that belongs to the state it runs in.

### Where actions can come from

The UI moves units with `UnitManager.RequestOperation` and ends turns with `UI.RequestAction`. See [game-api.md](game-api.md). These are request functions. The engine checks each action and applies it only if it is legal. The design requires this path. See [design/core/in-game-lua.md](../design/core/in-game-lua.md).

We assume, without confirmation yet, that the core mod's action API runs in a UI state that the mod adds. The phase 0 gate tests it.

The game's Lua files never call `UnitManager.MoveUnit`, so don't rely on it. Checked on 2026-10-16. Gameplay scenario scripts do use `UnitManager.InitUnit` and `UnitManager.PlaceUnit`, for example in `DLC/VikingsScenario/Scripts/VikingScenario.lua`.

### State names from other projects

Two community projects name the states they use. Both states appear in the [Windows state list](#lua-state-list). Their uses are unconfirmed on Windows. See [tuner-protocol.md](tuner-protocol.md#what-we-know-now) for the projects.

| State | Use | Source |
| --- | --- | --- |
| `GameCore_Tuner` | Read-only gameplay state. civ6-logger uses it for almost all reads | [civ6-logger ARCHITECTURE.md](https://github.com/PatrickJYKang/civ6-logger/blob/c21795250050447c89d42858afdf3decbac49bd8/docs/ARCHITECTURE.md), "Two ports, and which Lua state to use" |
| `InGame` | UI state. civ6-logger uses it for getters that `GameCore_Tuner` lacks, such as the current government. civ6-mcp sends its commands to it | civ6-logger, same section. [civ6-mcp README](https://github.com/lmwilki/civ6-mcp/tree/dd2019056371b92ea4854e879ddf05a8cad95e8a), "How it works" |

civ6-mcp sends commands to `InGame`, which matches the assumption that the action API runs in a UI state.

## Method

1. Connect FireTuner to a running game and copy the full state list here.
2. Run the same probe in each relevant state:

   ```lua
   print(type(UnitManager.RequestOperation), type(UI), type(UI and UI.RequestAction), type(Game.GetLocalPlayer))
   ```

3. Load the core mod and check which new states appear.

## Results

### Lua state list

FireTuner listed 124 states in a Duel game with Gathering Storm rules, sorted by name in the state dropdown. `SaveGameMenu` appears twice. FireTuner opens in `Main State`. The main menu shows a different, shorter set of states. After a return to the main menu and a reload of the save, the in-game list came back. civ6-logger reports about 98 states, so the count depends on the platform, the ruleset, or the game. Captured on 2026-10-19:

`ActionPanel`, `AdvisorPopup`, `ARXManager`, `Automation_NarrationPopup`, `BoostUnlockedPopup`, `CameraManager`, `ChatPanel`, `ChooseArtifact`, `CityBannerManager`, `CityPanel`, `CityPanelCulture`, `CityPanelOverview`, `CityPanelPower`, `CityStates`, `CivicsChooser`, `CivicsTree`, `CivilopediaScreen`, `ClimateScreen`, `ConfirmKick`, `DebugHotloadCache`, `DeclareWarPopup`, `DedicationPopup`, `DiplomacyActionView`, `DiplomacyDealView`, `DiplomacyRibbon`, `DisloyalCityChooser`, `DistrictPlotIconManager`, `EdgeScroll`, `EndGameMenu`, `EraCompletePopup`, `EraProgressPanel`, `EraReviewPopup`, `EspionageChooser`, `EspionageEscape`, `EspionageOverview`, `EspionagePopup`, `EventPopup`, `ExpansionIntro`, `FullscreenMapPopup`, `GameCore_Tuner`, `GenVFX`, `GlobalResourcePopup`, `GovernmentScreen`, `GovernorAssignmentChooser`, `GovernorDetailsPanel`, `GovernorPanel`, `GreatPeoplePopup`, `GreatWorkShowcase`, `GreatWorksOverview`, `HistoricMoments`, `HotSeatBackground`, `InGame`, `InGamePopup`, `InGameTopOptionsMenu`, `InvitePopup`, `LaunchBar`, `LeaderScene`, `LoadGameMenu`, `Main State`, `MapLabelManager`, `MapPinListPanel`, `MapPinManager`, `MapPinPopup`, `MapSearchPanel`, `MinimapPanel`, `ModalLensPanel`, `MultiplayerTurnManager`, `NaturalDisasterPopup`, `NaturalWonderPopup`, `NewTurnPanel`, `NotificationPanel`, `Options`, `PantheonChooser`, `PartialScreenHooks`, `PausePanel`, `PBCNotificationPopup`, `PlayerChange`, `PlotInfo`, `PlotToolTip`, `PowerLensManager`, `ProductionManager`, `ProductionPanel`, `ProjectBuiltPopup`, `RazeCity`, `ReligionScreen`, `ReportScreen`, `ReportsList`, `ResearchChooser`, `RockBandMoviePopup`, `RockBandPopup`, `SaveGameMenu`, `SelectedUnit`, `SettlerInfluenceIconManager`, `SettlerWarningIconManager`, `StatusMessagePanel`, `StrategicView`, `SwitchLayoutPopup`, `TechCivicCompletedPopup`, `TechTree`, `TopPanel`, `TourismBannerManager`, `TradeOriginChooser`, `TradeOverview`, `TradeRouteChooser`, `TutorialGoals`, `TutorialUIRoot`, `TutorialWorldAnchor`, `UnitCaptured`, `UnitFlagManager`, `UnitPanel`, `UnitPromotionPopup`, `WonderBuiltPopup`, `WorldCongress`, `WorldCongressBetweenTurns`, `WorldCongressIntro`, `WorldCongressPopup`, `WorldCrisisPopup`, `WorldCrisisTracker`, `WorldInput`, `WorldRankings`, `WorldTracker`, `WorldViewIconsManager`, `WorldViewPlotMessages`

### API probe by state

| State | `RequestOperation` | `UI` | `UI.RequestAction` | `Game.GetLocalPlayer` |
| --- | --- | --- | --- | --- |
| `InGame` | `function` | `table` | `function` | `function` |

Date checked: game files on 2026-10-16. Running game on Windows: 2026-10-19.
