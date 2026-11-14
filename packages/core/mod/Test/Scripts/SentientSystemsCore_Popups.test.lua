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
	env.UI = {
		ReferenceCurrentEvent = function()
			return 73360
		end,
		PlaySound = Record("PlaySound"),
		ReleaseEventID = Record("ReleaseEventID"),
		SetInterfaceMode = Record("SetInterfaceMode"),
	}
	env.UIManager = { DequeuePopup = Record("DequeuePopup") }
	env.Input = { PopContext = Record("PopContext") }
	env.UILens = { RestoreActiveLens = Record("RestoreActiveLens") }
	env.InterfaceModeTypes = { SELECTION = -1615000917 }
	env.ContextPtr = {
		LookUpControl = function(_, path)
			return path
		end,
	}
	env.LuaEvents = { WonderBuiltPopup_Closed = Record("WonderBuiltPopup_Closed") }
	Game.run(env, "Scripts/SentientSystemsCore_Popups.lua")
end)

describe("SentientSystems_CloseWonderPopup", function()
	it("closes the popup and releases its event twice, as the popup's Close does", function()
		env.SentientSystems_CloseWonderPopup()

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
end)

describe("SentientSystems_SendPopupSignals", function()
	it("sends the closed signal of each popup closed, once", function()
		env.SentientSystems_CloseWonderPopup()
		env.SentientSystems_CloseWonderPopup()
		calls = {}

		env.SentientSystems_SendPopupSignals()
		env.SentientSystems_SendPopupSignals()

		assert.same({ { "WonderBuiltPopup_Closed" }, { "WonderBuiltPopup_Closed" } }, calls)
	end)

	it("sends nothing when no popup closed", function()
		env.SentientSystems_SendPopupSignals()

		assert.same({}, calls)
	end)
end)
