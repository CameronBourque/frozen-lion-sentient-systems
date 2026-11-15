local Game = require("Game")

local env
-- The game calls made, in order.
local calls

local function Record(name)
	return function(...)
		local args = { ... }

		-- Drops the self argument of a method call.
		if type(args[1]) == "table" then
			table.remove(args, 1)
		end

		calls[#calls + 1] = { name, unpack(args) }
	end
end

-- Returns the calls with the given name.
local function CallsNamed(name)
	local found = {}

	for _, call in ipairs(calls) do
		if call[1] == name then
			found[#found + 1] = call
		end
	end

	return found
end

before_each(function()
	local eventID = 73360

	calls = {}
	env = Game.new()
	env.UI = {
		ReferenceCurrentEvent = function()
			return eventID
		end,
		PlaySound = Record("PlaySound"),
		ReleaseEventID = Record("ReleaseEventID"),
		SetInterfaceMode = Record("SetInterfaceMode"),
		ClearTemporaryPlotVisibility = Record("ClearTemporaryPlotVisibility"),
	}
	env.UIManager = { DequeuePopup = Record("DequeuePopup") }
	env.Input = { PopContext = Record("PopContext") }
	env.UILens = { RestoreActiveLens = Record("RestoreActiveLens") }
	env.InterfaceModeTypes = { SELECTION = -1615000917 }
	env.Events = { StopAllCameraAnimations = Record("StopAllCameraAnimations") }
	env.ContextPtr = {
		LookUpControl = function(_, path)
			return path
		end,
	}
	env.LuaEvents = {
		WonderBuiltPopup_Closed = Record("WonderBuiltPopup_Closed"),
		NaturalDisasterPopup_Closed = Record("NaturalDisasterPopup_Closed"),
	}
	env.GameInfo = {
		RandomEvents = {
			[3] = { RandomEventType = "RANDOM_EVENT_FLOOD_MODERATE" },
			[40] = { RandomEventType = "RANDOM_EVENT_COMET_STRIKE" },
			[41] = { RandomEventType = "RANDOM_EVENT_SOLAR_FLARE" },
		},
		RandomEvent_Presentation = {
			RANDOM_EVENT_FLOOD_MODERATE = { Animation = "REVEAL_FLOOD" },
			RANDOM_EVENT_COMET_STRIKE = { Animation = "REVEAL_COMET", SequenceType = "SCENE_EVENT_TRIGGER" },
		},
	}
	Game.run(env, "Scripts/SentientSystemsCore_Popups.lua")
end)

describe("SentientSystems_ClosePopup", function()
	it("closes the wonder popup and releases its event twice, as the popup's Close does", function()
		env.SentientSystems_ClosePopup("WonderBuiltPopup")

		assert.same({
			{ "PlaySound", "Stop_Wonder_Tracks" },
			{ "DequeuePopup", "/InGame/WonderBuiltPopup" },
			{ "PopContext" },
			{ "ReleaseEventID", 73360 },
			{ "ReleaseEventID", 73360 },
			{ "SetInterfaceMode", -1615000917 },
			{ "RestoreActiveLens" },
		}, calls)
	end)

	it("clears the disaster's plots and stops its sounds and camera before the disaster popup closes", function()
		env.SentientSystems_ClosePopup("NaturalDisasterPopup")

		assert.same({ "ClearTemporaryPlotVisibility", "NaturalDisaster" }, calls[1])
		assert.equal(12, #CallsNamed("PlaySound"))
		assert.same({ "StopAllCameraAnimations" }, calls[14])
		assert.same({ "DequeuePopup", "/InGame/NaturalDisasterPopup" }, calls[15])
		assert.equal(2, #CallsNamed("ReleaseEventID"))
	end)
end)

describe("SentientSystems_IsSequencedDisaster", function()
	it("is true for a disaster whose animation drives its popup", function()
		assert.is_true(env.SentientSystems_IsSequencedDisaster(40))
	end)

	it("is false for another disaster, one with no presentation, or an unknown type", function()
		assert.is_false(env.SentientSystems_IsSequencedDisaster(3))
		assert.is_false(env.SentientSystems_IsSequencedDisaster(41))
		assert.is_false(env.SentientSystems_IsSequencedDisaster(99))
	end)
end)

describe("SentientSystems_FinishPopups", function()
	it("sends the closed signal of each popup closed, once", function()
		env.SentientSystems_ClosePopup("WonderBuiltPopup")
		env.SentientSystems_ClosePopup("NaturalDisasterPopup")
		calls = {}

		env.SentientSystems_FinishPopups()
		env.SentientSystems_FinishPopups()

		assert.same({ { "WonderBuiltPopup_Closed" }, { "NaturalDisasterPopup_Closed" } }, calls)
	end)

	it("releases the second lock of a disaster whose animation drives its popup, once", function()
		env.SentientSystems_ReleaseDisasterLock(40)

		assert.same({}, calls)
		env.SentientSystems_FinishPopups()
		env.SentientSystems_FinishPopups()

		assert.same({ { "ReleaseEventID", 73360 }, { "ReleaseEventID", 73360 } }, calls)
	end)

	it("releases nothing for another disaster", function()
		env.SentientSystems_ReleaseDisasterLock(3)
		env.SentientSystems_FinishPopups()

		assert.same({}, calls)
	end)
end)
