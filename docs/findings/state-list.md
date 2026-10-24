# Lua state list

Status: open. The state list, how it changes over a session, and what the tuner does during a load are confirmed in a running game on Windows. Whether a mod can run Lua in the front end, and whether Lua can press the loading screen's button, are open.

The Lua states the tuner lists in a running game, and how the list changes when the player opens menus, quits to the main menu, or loads a save. What each state can call is in [lua-contexts.md](lua-contexts.md).

## Questions

1. Can a mod run Lua in the front end, so that it can report when the player moves between the main menu, the setup screen, and a game?
2. Can Lua start a loaded game from the loading screen, in place of the player's click on its button? A tool that starts test presets needs this, because commands return nothing until after the click. The game clicks it for the player in some cases. See [state list over a session](#state-list-over-a-session).

## What we know now

### State list over a session

| Item | Value | Status |
| --- | --- | --- |
| In-game menus | Opening in-game menus, such as the tech tree and a city screen, doesn't change the state list. Each menu is one of the states that always exist | Confirmed |
| Quit to the main menu | The tuner socket stays open. The list becomes the 32 front-end states, such as `MainMenu`, `FrontEnd`, `Lobby`, and `StagingRoom`. `Main State` stays 0 and `DebugHotloadCache` stays 1 | Confirmed |
| A command to a state that's gone | The tag 3 reply is `ERR:Invalid Lua State`, and no output comes back | Confirmed |
| Loading a game | From the start of a load until the click, the tuner doesn't answer `LSQ:`, and commands get no output and no error. FireTuner still lists the in-game states once the button shows, with the core mod on or off. How it gets them is not known. Seen in four `watch-states` loads and two FireTuner loads | Confirmed, 2026-10-23 |
| Output during a load | The tuner sends prints while the game loads. The bridge got the core mod's `CORE_LOADED` line during the load, and a print from `Events.LoadGameViewStateDone` as the button showed, 25 to 38 s before the click | Confirmed, two loads, 2026-10-23 |
| The click | `Events.LoadScreenClose` fires first. Its print reached the bridge 14 to 27 ms before the socket reset. The bridge reconnected 0.6 s after the reset, and its first command answered 0.1 s after that. FireTuner reconnects too, and goes back to `Main State`. `Lua.log` has the two events in this order in every load | Confirmed, two loads, 2026-10-23 |
| Auto-click | `OnLoadGameViewStateDone` in `<game>\Base\Assets\UI\FrontEnd\LoadScreen.lua` clicks the button for the player in a resync load, in any multiplayer game, hotseat included, in World Builder, and when `Automation.IsAutoStartEnabled()` is true. Then both events fire one after the other | From game files, 2026-10-23 |
| Indexes after a load | After a reload of the same save, all 122 in-game states other than `Main State` and `DebugHotloadCache` had their old indexes. The core mod's state adds one: with the mod on, `SentientSystemsCore_UI` is 109, and every state after it moves up by one, so `InGame` is 120, not 119 | Confirmed, 2026-10-21 and 2026-10-23 |
| Live reload | Editing the core mod's UI Lua file while a game runs rebuilds that UI context, and its load line prints again. This works in single player and in hotseat. Editing the gameplay Lua file doesn't reload it. Not measured: the delay, whether it needs `EnableTuner 1`, and what the reload resets | Confirmed, 2026-10-22 |
| `ContextPtr:GetID()` | Returns the state's name in a UI state: `InGame` in `InGame`, and `PlotInfo` in `PlotInfo`. `Main State` has no `ContextPtr` | Confirmed |

## Method

1. Connect FireTuner to a running game and copy the full state list here.
2. Close FireTuner, and run `npm run watch-states --workspace packages/core/bridge`. Open a few in-game menus. Save, quit to the main menu, and load the save. Click the loading screen's button to start the game, then stop the script.
3. To see what a client gets at the loading screen, load a save and wait at the loading screen's button without clicking it. Check whether the client lists the in-game states. Do it four times: with `watch-states` and with FireTuner, each with the core mod off and on.
4. To find when the loading screen's events fire, add these temporary probes to the end of `SentientSystemsCore_UI.lua`:

   ```lua
   local function Probe(name)
   	return SentientSystems_CatchErrors(name, function()
   		SentientSystems_Print("PROBE", name, Game.GetCurrentGameTurn())
   	end)
   end

   Events.LoadGameViewStateDone.Add(Probe("LoadGameViewStateDone"))
   Events.LoadScreenClose.Add(Probe("LoadScreenClose"))
   ```

   `PROBE` isn't a kind the bridge knows, so the bridge logs each probe as a `bad_line` warning with its time. Close FireTuner, and run `npm run dev --workspace packages/core/bridge`. Load a save, wait at the button for 30 s, then click it. Check which probes the bridge logged, and when `core_version` came after the click. Compare them with `Lua.log`, which gets every print. Do it twice. Then do one load in FireTuner. Before and after the click, run `SentientSystems_Print("PING")` in `SentientSystemsCore_UI`, and note whether it prints.

## Results

### Lua state list

FireTuner listed 124 states in a Duel game with Gathering Storm rules, sorted by name in the state dropdown. `SaveGameMenu` appears twice. FireTuner opens in `Main State`. The main menu shows a different, shorter set of states. After a return to the main menu and a reload of the save, the in-game list came back. civ6-logger reports about 98 states, so the count depends on the platform, the ruleset, or the game. Captured on 2026-10-19:

`ActionPanel`, `AdvisorPopup`, `ARXManager`, `Automation_NarrationPopup`, `BoostUnlockedPopup`, `CameraManager`, `ChatPanel`, `ChooseArtifact`, `CityBannerManager`, `CityPanel`, `CityPanelCulture`, `CityPanelOverview`, `CityPanelPower`, `CityStates`, `CivicsChooser`, `CivicsTree`, `CivilopediaScreen`, `ClimateScreen`, `ConfirmKick`, `DebugHotloadCache`, `DeclareWarPopup`, `DedicationPopup`, `DiplomacyActionView`, `DiplomacyDealView`, `DiplomacyRibbon`, `DisloyalCityChooser`, `DistrictPlotIconManager`, `EdgeScroll`, `EndGameMenu`, `EraCompletePopup`, `EraProgressPanel`, `EraReviewPopup`, `EspionageChooser`, `EspionageEscape`, `EspionageOverview`, `EspionagePopup`, `EventPopup`, `ExpansionIntro`, `FullscreenMapPopup`, `GameCore_Tuner`, `GenVFX`, `GlobalResourcePopup`, `GovernmentScreen`, `GovernorAssignmentChooser`, `GovernorDetailsPanel`, `GovernorPanel`, `GreatPeoplePopup`, `GreatWorkShowcase`, `GreatWorksOverview`, `HistoricMoments`, `HotSeatBackground`, `InGame`, `InGamePopup`, `InGameTopOptionsMenu`, `InvitePopup`, `LaunchBar`, `LeaderScene`, `LoadGameMenu`, `Main State`, `MapLabelManager`, `MapPinListPanel`, `MapPinManager`, `MapPinPopup`, `MapSearchPanel`, `MinimapPanel`, `ModalLensPanel`, `MultiplayerTurnManager`, `NaturalDisasterPopup`, `NaturalWonderPopup`, `NewTurnPanel`, `NotificationPanel`, `Options`, `PantheonChooser`, `PartialScreenHooks`, `PausePanel`, `PBCNotificationPopup`, `PlayerChange`, `PlotInfo`, `PlotToolTip`, `PowerLensManager`, `ProductionManager`, `ProductionPanel`, `ProjectBuiltPopup`, `RazeCity`, `ReligionScreen`, `ReportScreen`, `ReportsList`, `ResearchChooser`, `RockBandMoviePopup`, `RockBandPopup`, `SaveGameMenu`, `SelectedUnit`, `SettlerInfluenceIconManager`, `SettlerWarningIconManager`, `StatusMessagePanel`, `StrategicView`, `SwitchLayoutPopup`, `TechCivicCompletedPopup`, `TechTree`, `TopPanel`, `TourismBannerManager`, `TradeOriginChooser`, `TradeOverview`, `TradeRouteChooser`, `TutorialGoals`, `TutorialUIRoot`, `TutorialWorldAnchor`, `UnitCaptured`, `UnitFlagManager`, `UnitPanel`, `UnitPromotionPopup`, `WonderBuiltPopup`, `WorldCongress`, `WorldCongressBetweenTurns`, `WorldCongressIntro`, `WorldCongressPopup`, `WorldCrisisPopup`, `WorldCrisisTracker`, `WorldInput`, `WorldRankings`, `WorldTracker`, `WorldViewIconsManager`, `WorldViewPlotMessages`

### State lifecycle

`watch-states` listed the states every 5 s on Windows on 2026-10-21, in the same game. The script's output showed up late, so the times in the table may lag the player's actions by an unknown amount. On 2026-10-23, four more `watch-states` loads, three with the core mod on and one with it off, matched this table. FireTuner listed the in-game states before the click in the same loads, so the client makes the difference, not the mod. `watch-states` shows only the frames that answer its own requests, so it can't show prints. The bridge shows them. See [tuner-protocol.md](tuner-protocol.md#what-we-know-now).

| Time | What the player did | What the script saw |
| --- | --- | --- |
| 15:23:31 | Nothing yet | 124 states, `InGame` at 119. The three `ContextPtr:GetID()` checks gave `no ContextPtr`, `InGame`, and `PlotInfo` |
| 15:23:31 to 15:25:56 | Opened in-game menus | No change |
| 15:25:56 | Quit to the main menu | 32 states, with no `InGame`. `print("still here")` sent to index 119 got `ERR:Invalid Lua State` |
| 15:26:52 to 15:27:42 | Loaded the save, and waited at the loading screen's button | No reply to `LSQ:` in 5 s, six times |
| 15:27:48 | Clicked the button | The socket reset with `ECONNRESET`. The script reconnected at once, and one more `LSQ:` got no reply |
| 15:27:57 | Nothing | 124 states, `InGame` at 119, and every in-game state at its old index |

The main menu's 32 states are `Main State`, `DebugHotloadCache`, `Options`, `CreditsScreen`, `My2K`, `LoadGameMenu` three times, `PBCNotifyRemind`, `Lobby`, `Mods`, `SaveGameMenu` twice, `MultiSelectWindow`, `CityStatePicker`, `LeaderPicker`, `HostGame`, `ConfirmKick`, `EditHotseatPlayer`, `StagingRoom`, `FrontEndPopup`, `CivRoyaleIntro`, `PiratesIntro`, `CrossPlayLogin`, `MainMenu`, `StateTransition`, `JoiningRoom`, `UserSetupWarning`, `SwitchLayoutPopup`, `Test`, `FrontEnd`, and `InvitePopup`.

Date checked: running game on Windows on 2026-10-19, 2026-10-21, and 2026-10-23, and `LoadScreen.lua` in the game files on 2026-10-23.
