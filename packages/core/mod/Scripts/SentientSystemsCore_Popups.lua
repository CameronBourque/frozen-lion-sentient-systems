-- Closes the popups that wait for a click, for an agent player, who can't see
-- them. UI states only. See docs/design/core/mod/README.md#popups.

-- The popups closed, by the name of their context. A plain Close is
-- UIManager:DequeuePopup, then the closed signal, if it has one. A screen
-- shows by unhiding its context instead, and its Close hides it and plays its
-- stop sounds. closeEvent names a LuaEvent that runs the popup's own Close,
-- for a Close that does more, and closeButton names the button that does, to
-- press. A popup with onlyWithoutSession stays open while the player has a
-- diplomacy session open, and one with stopsCamera has a camera move that
-- starts after its Close.
SENTIENTSYSTEMS_POPUPS = {
	-- WonderBuiltPopup.lua. It locks the event queue, and its Close shows the
	-- next wonder or unlocks.
	{ name = "WonderBuiltPopup", closeButton = "Close" },
	-- NaturalWonderPopup.lua. It locks the event queue, and its fly-around of
	-- the wonder starts after the batch of game events ends.
	{ name = "NaturalWonderPopup", closeButton = "Close", stopsCamera = true },
	-- NaturalDisasterPopup.lua, in Gathering Storm. It locks the event queue.
	-- A meteor shower or comet would lock again on RandomEventOccurred, but
	-- only while its popup is open.
	{ name = "NaturalDisasterPopup", closeButton = "Close" },
	-- HeroesPopup.lua, in the Heroes and Legends mode
	{ name = "HeroesPopup" },
	-- SecretSocietyPopup.lua, in the Secret Societies mode
	{ name = "SecretSocietyPopup" },
	-- HistoricMoments.lua, in Rise and Fall. The launch bar shows the timeline
	-- open until the closed signal.
	{ name = "HistoricMoments", closed = "HistoricMoments_Closed" },
	-- EraReviewPopup.lua, in Rise and Fall. Its Continue opens the dedication
	-- popup, which the dedication action doesn't need.
	{ name = "EraReviewPopup" },
	-- WorldCongressIntro.lua, in Gathering Storm. Its Continue opens the voting
	-- screen, which the congress vote action doesn't need.
	{ name = "WorldCongressIntro" },
	-- WorldCongressPopup.lua, in Gathering Storm: the voting and results
	-- screen. Its ClosePopup also pops its input context, and outside a session
	-- tells the game the player looked at the congress.
	{ name = "WorldCongressPopup", closeEvent = "DiplomacyActionView_HideCongress" },
	-- WorldCrisisPopup.lua, in Gathering Storm. An emergency there begins
	-- through the congress vote, so the popup only shows it. Its OK also sends
	-- ACCEPT_EMERGENCY, which changes nothing the player can see.
	{ name = "WorldCrisisPopup" },
	-- EspionagePopup.lua, when a spy's mission ends. A mission that ends while
	-- it shows waits in the popup's own list, which only its Close opens, so
	-- that one never shows.
	{ name = "EspionagePopup" },
	-- ProjectBuiltPopup.lua, for a project with a popup, such as a space race
	-- launch. It locks the event queue, and its Close shows the next project or
	-- unlocks.
	{ name = "ProjectBuiltPopup", closeButton = "Close" },
	-- RockBandMoviePopup.lua, in Gathering Storm, for a concert. It holds the
	-- event queue, and its Close stops the concert's camera and animation and
	-- opens RockBandPopup.
	{ name = "RockBandMoviePopup", closeButton = "Close" },
	-- RockBandPopup.lua, in Gathering Storm: the concert's result
	{ name = "RockBandPopup" },
	-- GreatWorkShowcase.lua, for each great work the player creates
	{
		name = "GreatWorkShowcase",
		isScreen = true,
		sounds = { "Stop_Great_Music", "Stop_Speech_GreatWriting", "Stop_Great_Works_Gallery_Ambience" },
	},
	-- DiplomacyActionView.lua: the leader screen. With no session open it shows
	-- only the overview, as after a peace, and its X runs its own Close.
	{ name = "DiplomacyActionView", isScreen = true, closeButton = "CloseButton", onlyWithoutSession = true },
}

-- Whether a popup with a camera move closed since the camera was last stopped.
local isCameraStopPending = false

-- Returns whether a popup's context is showing.
local function IsPopupOpen(popup, context)
	if popup.onlyWithoutSession and SentientSystems_FindOpenSession(Game.GetLocalPlayer()) ~= nil then
		return false
	end

	if popup.isScreen then
		return not context:IsHidden()
	end

	return UIManager:IsInPopupQueue(context)
end

-- Closes a popup, as its Close does.
local function ClosePopup(popup, context)
	if popup.closeEvent ~= nil then
		LuaEvents[popup.closeEvent]()
	elseif popup.closeButton ~= nil then
		ContextPtr:LookUpControl("/InGame/" .. popup.name .. "/" .. popup.closeButton):DoLeftClick()
	elseif popup.isScreen then
		context:SetHide(true)
	else
		UIManager:DequeuePopup(context)
	end

	for _, sound in ipairs(popup.sounds or {}) do
		UI.PlaySound(sound)
	end

	if popup.closed ~= nil then
		LuaEvents[popup.closed]()
	end

	if popup.stopsCamera then
		isCameraStopPending = true
	end
end

-- The IDs of the InGamePopup dialogs closed. The shared dialog also asks the
-- player to confirm a strike or a city, so the others stay open.
local CLOSED_DIALOGS = {
	-- UnitCaptured.lua, when the player loses or captures a unit
	UnitCaptured = true,
}

-- Whether a closed dialog was raised and is still waiting to close.
local isDialogPending = false

-- Remembers a dialog raised through InGamePopup, to close at the end of the
-- batch, once InGamePopup has shown it. Call it from OnRaisePopupInGame.
function SentientSystems_NoteRaisedDialog(id)
	if CLOSED_DIALOGS[id] then
		isDialogPending = true
	end
end

-- Returns the first control with the ID under a control, searching its
-- children. A path doesn't reach the controls of InGamePopup, but its
-- children do.
local function FindChild(control, id)
	for _, child in ipairs(control:GetChildren() or {}) do
		if child:GetID() == id then
			return child
		end

		local found = FindChild(child, id)

		if found ~= nil then
			return found
		end
	end

	return nil
end

-- Presses the button of the dialog waiting to close, once it shows. Its only
-- button runs InGamePopup's own close.
local function CloseRaisedDialog()
	local context = ContextPtr:LookUpControl("/InGame/InGamePopup")
	local root = context and FindChild(context, "PopupRoot")

	if root == nil or root:IsHidden() then
		return
	end

	local button = FindChild(root, "Button")

	if button ~= nil then
		isDialogPending = false
		button:DoLeftClick()
	end
end

-- Closes each popup that is open, and the dialog waiting to close. A
-- popup whose mode is off has no context. Call it when a batch of game events
-- ends and when the interface is idle, since they open from notifications at
-- any time, or from their own queue once nothing else shows.
function SentientSystems_ClosePopups()
	for _, popup in ipairs(SENTIENTSYSTEMS_POPUPS) do
		local context = ContextPtr:LookUpControl("/InGame/" .. popup.name)

		if context ~= nil and IsPopupOpen(popup, context) then
			ClosePopup(popup, context)
		end
	end

	if isDialogPending then
		CloseRaisedDialog()
	end
end

-- Stops the camera move of each popup closed since the last call, such as the
-- natural wonder's fly-around, which keeps the camera until it stops. The move
-- starts after the batch of game events ends. Call it when the game finishes
-- playing back its events.
function SentientSystems_StopPopupCamera()
	if isCameraStopPending then
		isCameraStopPending = false
		Events.StopAllCameraAnimations()
	end
end
