-- Closes the popups that wait for a click, for an agent player, who can't see
-- them. UI states only. See docs/design/core/mod/README.md#popups.

-- The sounds that NaturalDisasterPopup.lua stops in Close.
local DISASTER_SOUNDS = {
	"Stop_Disaster_Blizzard_Movie_Loop", "Stop_Disaster_Flood_Movie_Loop", "Stop_Disaster_Hurricane_Movie_Loop",
	"Stop_Disaster_Sandstorm_Movie_Loop", "Stop_Disaster_Tornado_Movie_Loop", "Stop_Disaster_Volcano_Movie_Loop",
	"Stop_Disaster_Drought_Movie_Loop", "Stop_Disaster_Meltdown_Movie_Loop", "Stop_Disaster_CometStrike_Movie_Loop",
	"Stop_Disaster_ForestFire_Movie_Loop", "Stop_Disaster_MeteorShower_Movie_Loop",
	"Stop_Disaster_SolarFlare_Movie_Loop",
}

-- The popups closed, by the name of their context. Each fires <name>_Shown
-- right after its lock, and <name>_Closed when it closes. stop holds the steps
-- of its Close that come before the closed signal.
SENTIENTSYSTEMS_POPUPS = {
	-- WonderBuiltPopup.lua
	WonderBuiltPopup = {
		stop = function()
			UI.PlaySound("Stop_Wonder_Tracks")
		end,
	},
	-- NaturalWonderPopup.lua
	NaturalWonderPopup = {
		stop = function()
			UI.ClearTemporaryPlotVisibility("NaturalWonder")
			UI.PlaySound("Stop_Speech_NaturalWonders")
			Events.StopAllCameraAnimations()
		end,
	},
	-- NaturalDisasterPopup.lua, in Gathering Storm
	NaturalDisasterPopup = {
		stop = function()
			UI.ClearTemporaryPlotVisibility("NaturalDisaster")

			for _, sound in ipairs(DISASTER_SOUNDS) do
				UI.PlaySound(sound)
			end

			Events.StopAllCameraAnimations()
		end,
	},
}

-- The popups that hold nothing, by the name of their context. Each Close is
-- UIManager:DequeuePopup, then the closed signal, if it has one.
SENTIENTSYSTEMS_PLAIN_POPUPS = {
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
}

-- Closes each plain popup that is open. A popup whose mode is off has no
-- context. Call it when a batch of game events ends and when the interface is
-- idle, since they open from notifications at any time, or from their own
-- queue once nothing else shows.
function SentientSystems_ClosePlainPopups()
	for _, popup in ipairs(SENTIENTSYSTEMS_PLAIN_POPUPS) do
		local context = ContextPtr:LookUpControl("/InGame/" .. popup.name)

		if context ~= nil and UIManager:IsInPopupQueue(context) then
			UIManager:DequeuePopup(context)

			if popup.closed ~= nil then
				LuaEvents[popup.closed]()
			end
		end
	end
end

-- The LuaEvents to send, and the event IDs to release, once the current batch
-- of game events ends.
local pendingSignals = {}
local pendingReleases = {}
-- Whether a popup closed since the camera was last stopped.
local isCameraStopPending = false

-- Releases an event twice: once for the reference the caller took, and once
-- for the popup's lock on it.
local function ReleaseLockedEvent(eventID)
	UI.ReleaseEventID(eventID)
	UI.ReleaseEventID(eventID)
end

-- Closes a popup, as its Close does. Its lock holds the engine's event queue,
-- so requests and the AI turns wait until someone presses Close. Call it from
-- the popup's Shown event, while the event that it locked is the current one.
function SentientSystems_ClosePopup(name)
	local eventID = UI.ReferenceCurrentEvent()

	SENTIENTSYSTEMS_POPUPS[name].stop()
	UIManager:DequeuePopup(ContextPtr:LookUpControl("/InGame/" .. name))
	Input.PopContext()
	ReleaseLockedEvent(eventID)
	UI.SetInterfaceMode(InterfaceModeTypes.SELECTION)
	UILens.RestoreActiveLens()
	-- InGame.lua hides the interface on the same Shown event, maybe after this
	-- call, so the closed signal waits for the end of the batch.
	pendingSignals[#pendingSignals + 1] = name .. "_Closed"
	isCameraStopPending = true
end

-- Returns whether a disaster's animation drives its popup. Its popup opens on
-- RandomEventStarted and locks again on RandomEventOccurred, as
-- ShouldShowOnRandomEventStarted in NaturalDisasterPopup.lua checks.
function SentientSystems_IsSequencedDisaster(type)
	local info = GameInfo.RandomEvents[type]
	local presentation = info and GameInfo.RandomEvent_Presentation[info.RandomEventType]

	return presentation ~= nil and presentation.SequenceType == "SCENE_EVENT_TRIGGER"
end

-- Releases the second lock of a disaster whose animation drives its popup.
-- The popup takes it on RandomEventOccurred, maybe after this listener, so the
-- release waits for the end of the batch. Call it from RandomEventOccurred.
function SentientSystems_ReleaseDisasterLock(type)
	if SentientSystems_IsSequencedDisaster(type) then
		pendingReleases[#pendingReleases + 1] = UI.ReferenceCurrentEvent()
	end
end

-- Sends the closed signals and releases the locks left since the last batch
-- ended.
function SentientSystems_FinishPopups()
	local signals, releases = pendingSignals, pendingReleases

	pendingSignals, pendingReleases = {}, {}

	for _, eventID in ipairs(releases) do
		ReleaseLockedEvent(eventID)
	end

	for _, name in ipairs(signals) do
		LuaEvents[name]()
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
