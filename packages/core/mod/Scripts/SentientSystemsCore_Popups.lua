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

-- The LuaEvents to send, and the event IDs to release, once the current batch
-- of game events ends.
local pendingSignals = {}
local pendingReleases = {}

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
