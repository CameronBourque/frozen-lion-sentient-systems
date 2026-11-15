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

	it("clears the natural wonder's plots and stops its speech and camera before the natural wonder popup closes", function()
		env.SentientSystems_ClosePopup("NaturalWonderPopup")

		assert.same({
			{ "ClearTemporaryPlotVisibility", "NaturalWonder" },
			{ "PlaySound", "Stop_Speech_NaturalWonders" },
			{ "StopAllCameraAnimations" },
			{ "DequeuePopup", "/InGame/NaturalWonderPopup" },
		}, { unpack(calls, 1, 4) })
		assert.equal(2, #CallsNamed("ReleaseEventID"))
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

describe("SentientSystems_StopPopupCamera", function()
	it("stops the camera once after popups close, and not when none has", function()
		env.SentientSystems_StopPopupCamera()
		env.SentientSystems_ClosePopup("WonderBuiltPopup")
		env.SentientSystems_ClosePopup("NaturalWonderPopup")
		calls = {}

		env.SentientSystems_StopPopupCamera()
		env.SentientSystems_StopPopupCamera()

		assert.same({ { "StopAllCameraAnimations" } }, calls)
	end)
end)

describe("SentientSystems_ClosePlainPopups", function()
	it("closes each plain popup in the popup queue, and skips the others and those with no context", function()
		local contexts = { ["/InGame/HeroesPopup"] = "heroes" }

		env.ContextPtr.LookUpControl = function(_, path)
			return contexts[path]
		end
		env.UIManager.IsInPopupQueue = function(_, context)
			return context == "heroes"
		end

		env.SentientSystems_ClosePlainPopups()
		contexts["/InGame/SecretSocietyPopup"] = "society"
		env.SentientSystems_ClosePlainPopups()

		assert.same({ { "DequeuePopup", "heroes" }, { "DequeuePopup", "heroes" } }, calls)
	end)

	it("closes the era review popup", function()
		env.ContextPtr.LookUpControl = function(_, path)
			return path == "/InGame/EraReviewPopup" and "review" or nil
		end
		env.UIManager.IsInPopupQueue = function()
			return true
		end

		env.SentientSystems_ClosePlainPopups()

		assert.same({ { "DequeuePopup", "review" } }, calls)
	end)

	it("hides the great work showcase when it shows, and stops its sounds", function()
		local hidden = false
		local showcase = {
			IsHidden = function()
				return hidden
			end,
			SetHide = function(_, isHidden)
				hidden = isHidden
				calls[#calls + 1] = { "SetHide", isHidden }
			end,
		}

		env.ContextPtr.LookUpControl = function(_, path)
			return path == "/InGame/GreatWorkShowcase" and showcase or nil
		end

		env.SentientSystems_ClosePlainPopups()
		env.SentientSystems_ClosePlainPopups()

		assert.same({
			{ "SetHide", true },
			{ "PlaySound", "Stop_Great_Music" },
			{ "PlaySound", "Stop_Speech_GreatWriting" },
			{ "PlaySound", "Stop_Great_Works_Gallery_Ambience" },
		}, calls)
	end)

	it("sends the closed signal of a plain popup that has one", function()
		env.ContextPtr.LookUpControl = function(_, path)
			return path == "/InGame/HistoricMoments" and "moments" or nil
		end
		env.UIManager.IsInPopupQueue = function()
			return true
		end
		env.LuaEvents.HistoricMoments_Closed = Record("HistoricMoments_Closed")

		env.SentientSystems_ClosePlainPopups()

		assert.same({ { "DequeuePopup", "moments" }, { "HistoricMoments_Closed" } }, calls)
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
