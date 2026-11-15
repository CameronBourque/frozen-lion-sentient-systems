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

before_each(function()
	calls = {}
	env = Game.new()
	env.UI = { PlaySound = Record("PlaySound") }
	env.UIManager = { DequeuePopup = Record("DequeuePopup") }
	env.Events = { StopAllCameraAnimations = Record("StopAllCameraAnimations") }
	env.ContextPtr = {
		LookUpControl = function(_, path)
			return path
		end,
	}
	env.LuaEvents = {}
	Game.run(env, "Scripts/SentientSystemsCore_Popups.lua")
end)

-- Shows the popups named, in the popup queue, each with a Close button that
-- records its press.
local function ShowLocked(...)
	local controls = {}

	for _, name in ipairs({ ... }) do
		controls["/InGame/" .. name] = name
		controls["/InGame/" .. name .. "/Close"] = { DoLeftClick = Record(name .. "Close") }
	end

	env.ContextPtr.LookUpControl = function(_, path)
		return controls[path]
	end
	env.UIManager.IsInPopupQueue = function()
		return true
	end
end

describe("the popups that lock the event queue", function()
	it("presses the Close button of the wonder, natural wonder, and disaster popups", function()
		ShowLocked("WonderBuiltPopup", "NaturalWonderPopup", "NaturalDisasterPopup")

		env.SentientSystems_ClosePopups()

		assert.same({ { "WonderBuiltPopupClose" }, { "NaturalWonderPopupClose" }, { "NaturalDisasterPopupClose" } }, calls)
	end)
end)

describe("SentientSystems_StopPopupCamera", function()
	it("stops the camera once after the natural wonder popup closes, and not after another popup", function()
		ShowLocked("WonderBuiltPopup")
		env.SentientSystems_ClosePopups()
		env.SentientSystems_StopPopupCamera()
		ShowLocked("NaturalWonderPopup")
		env.SentientSystems_ClosePopups()
		calls = {}

		env.SentientSystems_StopPopupCamera()
		env.SentientSystems_StopPopupCamera()

		assert.same({ { "StopAllCameraAnimations" } }, calls)
	end)
end)

describe("SentientSystems_ClosePopups", function()
	it("closes each popup in the popup queue, and skips the others and those with no context", function()
		local contexts = { ["/InGame/HeroesPopup"] = "heroes" }

		env.ContextPtr.LookUpControl = function(_, path)
			return contexts[path]
		end
		env.UIManager.IsInPopupQueue = function(_, context)
			return context == "heroes"
		end

		env.SentientSystems_ClosePopups()
		contexts["/InGame/SecretSocietyPopup"] = "society"
		env.SentientSystems_ClosePopups()

		assert.same({ { "DequeuePopup", "heroes" }, { "DequeuePopup", "heroes" } }, calls)
	end)

	it("closes the era review, emergency, and spy mission popups", function()
		env.ContextPtr.LookUpControl = function(_, path)
			return ({
				["/InGame/EraReviewPopup"] = "review",
				["/InGame/WorldCrisisPopup"] = "emergency",
				["/InGame/EspionagePopup"] = "spy",
			})[path]
		end
		env.UIManager.IsInPopupQueue = function()
			return true
		end

		env.SentientSystems_ClosePopups()

		assert.same({ { "DequeuePopup", "review" }, { "DequeuePopup", "emergency" }, { "DequeuePopup", "spy" } }, calls)
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

		env.SentientSystems_ClosePopups()
		env.SentientSystems_ClosePopups()

		assert.same({
			{ "SetHide", true },
			{ "PlaySound", "Stop_Great_Music" },
			{ "PlaySound", "Stop_Speech_GreatWriting" },
			{ "PlaySound", "Stop_Great_Works_Gallery_Ambience" },
		}, calls)
	end)

	it("closes the congress intro by dequeuing it, and the voting screen through its own close event", function()
		env.ContextPtr.LookUpControl = function(_, path)
			return ({ ["/InGame/WorldCongressIntro"] = "intro", ["/InGame/WorldCongressPopup"] = "voting" })[path]
		end
		env.UIManager.IsInPopupQueue = function()
			return true
		end
		env.LuaEvents.DiplomacyActionView_HideCongress = Record("DiplomacyActionView_HideCongress")

		env.SentientSystems_ClosePopups()

		assert.same({ { "DequeuePopup", "intro" }, { "DiplomacyActionView_HideCongress" } }, calls)
	end)

	it("presses the leader screen's close button when it shows with no session open", function()
		local openSession = 4
		local screen = {
			IsHidden = function()
				return false
			end,
		}
		local button = { DoLeftClick = Record("DoLeftClick") }

		env.Game = {
			GetLocalPlayer = function()
				return 0
			end,
		}
		env.SentientSystems_FindOpenSession = function(playerID)
			return playerID == 0 and openSession or nil
		end
		env.ContextPtr.LookUpControl = function(_, path)
			return ({ ["/InGame/DiplomacyActionView"] = screen, ["/InGame/DiplomacyActionView/CloseButton"] = button })[path]
		end

		env.SentientSystems_ClosePopups()
		assert.same({}, calls)
		openSession = nil
		env.SentientSystems_ClosePopups()

		assert.same({ { "DoLeftClick" } }, calls)
	end)

	it("presses the close button of the project and concert movie popups, then dequeues the concert result", function()
		local controls = {
			["/InGame/ProjectBuiltPopup"] = "project",
			["/InGame/ProjectBuiltPopup/Close"] = { DoLeftClick = Record("ProjectClose") },
			["/InGame/RockBandMoviePopup"] = "movie",
			["/InGame/RockBandMoviePopup/Close"] = { DoLeftClick = Record("MovieClose") },
			["/InGame/RockBandPopup"] = "result",
		}

		env.ContextPtr.LookUpControl = function(_, path)
			return controls[path]
		end
		env.UIManager.IsInPopupQueue = function()
			return true
		end

		env.SentientSystems_ClosePopups()

		assert.same({ { "ProjectClose" }, { "MovieClose" }, { "DequeuePopup", "result" } }, calls)
	end)

	it("sends the closed signal of a popup that has one", function()
		env.ContextPtr.LookUpControl = function(_, path)
			return path == "/InGame/HistoricMoments" and "moments" or nil
		end
		env.UIManager.IsInPopupQueue = function()
			return true
		end
		env.LuaEvents.HistoricMoments_Closed = Record("HistoricMoments_Closed")

		env.SentientSystems_ClosePopups()

		assert.same({ { "DequeuePopup", "moments" }, { "HistoricMoments_Closed" } }, calls)
	end)
end)

describe("the unit captured dialog", function()
	-- Returns a control with the ID and children given.
	local function Control(id, children, isHidden)
		return {
			GetID = function()
				return id
			end,
			GetChildren = function()
				return children
			end,
			IsHidden = function()
				return isHidden
			end,
		}
	end

	local function SetDialog(isHidden)
		local button = Control("Button", {})

		button.DoLeftClick = Record("DoLeftClick")

		local root = Control("PopupRoot", { Control("PopupStack", { Control("Row", { button }) }) }, isHidden)

		env.ContextPtr.LookUpControl = function(_, path)
			return path == "/InGame/InGamePopup" and Control("InGamePopup", { root }) or nil
		end
	end

	it("presses the dialog's button once it shows, after a unit captured raise", function()
		SetDialog(true)
		env.SentientSystems_NoteRaisedDialog("UnitCaptured")
		env.SentientSystems_ClosePopups()
		assert.same({}, calls)

		SetDialog(false)
		env.SentientSystems_ClosePopups()
		env.SentientSystems_ClosePopups()

		assert.same({ { "DoLeftClick" } }, calls)
	end)

	it("presses nothing while the shown dialog has no button", function()
		local root = Control("PopupRoot", { Control("PopupStack", {}) }, false)

		env.ContextPtr.LookUpControl = function(_, path)
			return path == "/InGame/InGamePopup" and Control("InGamePopup", { root }) or nil
		end
		env.SentientSystems_NoteRaisedDialog("UnitCaptured")
		env.SentientSystems_ClosePopups()

		assert.same({}, calls)
	end)

	it("leaves the dialog open for another raise, such as a strike to confirm", function()
		SetDialog(false)
		env.SentientSystems_NoteRaisedDialog("ConfirmWMDStrike")
		env.SentientSystems_ClosePopups()

		assert.same({}, calls)
	end)
end)
