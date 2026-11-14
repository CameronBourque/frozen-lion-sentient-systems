-- Closes the popups that wait for a click, for an agent player, who can't see
-- them. UI states only. See docs/design/core/mod/README.md#popups.

-- The LuaEvents to send once the current batch of game events ends.
local pendingSignals = {}

-- Closes the wonder built popup, as Close in WonderBuiltPopup.lua does. Its
-- lock holds the engine's event queue, so requests and the AI turns wait until
-- someone presses Close. Call it from the popup's Shown event, while the event
-- that the popup locked is still the current one.
function SentientSystems_CloseWonderPopup()
	local eventID = UI.ReferenceCurrentEvent()

	UI.PlaySound("Stop_Wonder_Tracks")
	UIManager:DequeuePopup(ContextPtr:LookUpControl("/InGame/WonderBuiltPopup"))
	Input.PopContext()
	-- Once for this reference and once for the popup's lock.
	UI.ReleaseEventID(eventID)
	UI.ReleaseEventID(eventID)
	UI.SetInterfaceMode(InterfaceModeTypes.SELECTION)
	UILens.RestoreActiveLens()
	-- InGame.lua hides the interface on the same Shown event, maybe after this
	-- call, so the closed signal waits for the end of the batch.
	pendingSignals[#pendingSignals + 1] = "WonderBuiltPopup_Closed"
end

-- Sends the closed signals of the popups closed since the last batch ended.
function SentientSystems_SendPopupSignals()
	local signals = pendingSignals

	pendingSignals = {}

	for _, name in ipairs(signals) do
		LuaEvents[name]()
	end
end
