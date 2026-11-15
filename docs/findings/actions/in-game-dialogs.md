# In-game dialogs

Status: confirmed. The unit captured dialog, and closing it with its own button from `SentientSystemsCore_UI`, are confirmed in a running game with Gathering Storm, with calls sent through the tuner. So is the core mod's own close.

The small dialogs that `PopupDialogInGame` raises through one shared context, `InGamePopup`, and how to close them from outside. Closing them for an agent player is [popups for agent players](../../roadmap/phase-1/done/popups.md#popups-for-agent-players).

## Questions

None open.

## What we know now

### The shared dialog

`PopupDialogInGame:new(id)` in `Base/Assets/UI/Popups/PopupDialog.lua` builds a dialog's options, and its `Open` fires `LuaEvents.OnRaisePopupInGame(id, options)`. Each option has a `Type`, `Title`, `Text`, or `Button`, and its `Content`. Confirmed in files.

`InGamePopup.lua` listens, fills its one dialog from the options, and calls `UIManager:PushModal(ContextPtr)`. Each button calls `OnClosePopup`, which calls `UIManager:PopModal` and closes the dialog, then the button's callback. Confirmed in files.

Its IDs are `UnitCaptured`, `CannotMoveWork`, `ConfirmICBMStrike`, `ConfirmWMDStrike`, `FoundCityAt`, `LastPlayer`, `PlayerKicked`, `TurnCommitFailed`, and the district and wonder placement confirmations. Confirmed in files.

Only `LuaEvents.Tutorial_TutorialEndHideBulkUI` runs `OnClosePopup` from outside, and `InGame.lua` hides the HUD on it too. Confirmed in files.

### Unit captured

`Base/Assets/UI/Popups/UnitCaptured.lua` raises the `UnitCaptured` dialog from `Events.UnitCaptured`, when the local player loses a unit or captures one, outside multiplayer. Its one button, **OK**, does nothing more. Confirmed in files.

On turn 85, barbarians captured a builder during the AI turns. `Events.UnitCaptured` fired with the player as the owner and 63 as the capturer, and `OnRaisePopupInGame` fired with `UnitCaptured`, the title, the text, and **OK**.

Turn 86 began with the dialog open, so it holds nothing. The text was "Allowing such a vulnerable unit to remain unprotected was not a wise choice. Your unit has been captured by Barbarians.", with `[NEWLINE]` between the sentences. Confirmed on Windows on 2026-11-15.

### The capture event

`Events.UnitCaptured(currentUnitOwner, unitID, owningPlayer, capturingPlayer)` fires in UI states for every capture, not only the local player's.

The dialog's text is `LOC_UNIT_CAPTURED` for a unit lost, or `LOC_CAPTURE_UNIT` for one taken, with the other civ's short name. Neither names the unit. Confirmed in files.

The player's knight captured a Vietnamese builder that `UnitManager.InitUnit` put next to it, through the attack action. A plain move onto it did nothing.

The event fired with 10, 7208987, 10, and 0, and the builder became the player's unit 22020282. Its old ID found a different unit of the player's, a trader, so the event's unit ID can't name the unit taken. Confirmed on Windows on 2026-11-15.

With the core mod's events section, the same capture, a concert, and the barbarians taking a builder during the AI turns each left an entry. On turn 86 the state's `events` held `unitCaptured`, `concert`, and `unitLost`, each with turn 85 and the popup's text. Confirmed on Windows on 2026-11-15.

### Closing it

`ContextPtr:LookUpControl("/InGame/InGamePopup")` from `SentientSystemsCore_UI` returns the context, but a path below it doesn't reach its controls. `GetChildren()` does: `PopupRoot`, then down to `PopupStack`, a `Row`, and the button, whose ID is `Button`.

`DoLeftClick()` on that button closed the dialog, with `PopupRoot` hidden. Confirmed on Windows on 2026-11-15.

With the core mod's close, the same capture left the dialog closed when turn 86 began. Its `Text` still held the capture text, and the log had no error. Confirmed on Windows on 2026-11-15.

## Method

1. In `SentientSystemsCore_UI`, add listeners that print `LuaEvents.OnRaisePopupInGame`'s ID and options, and `Events.UnitCaptured`'s arguments.
2. Leave a builder next to barbarians, end the turn, and read the log and whether `PopupRoot` is hidden.
3. Walk the context's controls with `GetChildren()`, printing each ID, whether it has `DoLeftClick`, and its text. Call `DoLeftClick()` on the button, and read `PopupRoot` again.

## Results

| Call | Lua state | Result | Date |
| --- | --- | --- | --- |
| `SentientSystems_EndTurn(0, true)` on turn 85, with a builder next to barbarians | `SentientSystemsCore_UI` | `UnitCaptured` with 0, 0, and 63, the `UnitCaptured` dialog raised, and turn 86 with it open | 2026-11-15 |
| `GetChildren()` from `/InGame/InGamePopup` down | `SentientSystemsCore_UI` | `PopupRoot`, `PopupStack`, `Text`, `Row`, and `Button` with `DoLeftClick` and the text **OK** | 2026-11-15 |
| `DoLeftClick()` on that button | `SentientSystemsCore_UI` | `PopupRoot` hidden, and `SELECTION` | 2026-11-15 |
| `SentientSystems_UnitAction(0, knight, "attack", 45, 30)` onto a Vietnamese builder | `SentientSystemsCore_UI` | `UnitCaptured` with 10, 7208987, 10, and 0, and the builder the player's, with ID 22020282 | 2026-11-15 |
| The same capture, a concert, and `SentientSystems_EndTurn(0, true)` with a builder next to barbarians, with the events section | `SentientSystemsCore_UI` | On turn 86, `events` held `unitCaptured`, `concert`, and `unitLost` from turn 85, and the dialog was closed | 2026-11-15 |
| `SentientSystems_EndTurn(0, true)` on turn 85 again, with the core mod's close | `SentientSystemsCore_UI` | Turn 86 with `PopupRoot` hidden, `Text` holding the capture text, and no error | 2026-11-15 |

Date checked: game files on 2026-11-15. Running game on Windows on 2026-11-15.
