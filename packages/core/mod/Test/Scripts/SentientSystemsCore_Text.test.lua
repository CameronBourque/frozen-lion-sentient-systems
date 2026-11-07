local Game = require("Game")

local env

before_each(function()
	env = Game.new()
	Game.run(env, "Scripts/SentientSystemsCore_Text.lua")
end)

describe("SentientSystems_GetTooltipLines", function()
	it("splits a tooltip at [NEWLINE] and drops the icons and the empty lines", function()
		local lines = env.SentientSystems_GetTooltipLines("MINE[NEWLINE][NEWLINE]Generating +1 [ICON_Tourism] Tourism[NEWLINE]  Lifetime: 30 [ICON_Tourism]")

		assert.same({ "MINE", "Generating +1 Tourism", "Lifetime: 30" }, lines)
	end)

	it("returns no lines for an empty tooltip", function()
		assert.same({}, env.SentientSystems_GetTooltipLines(""))
	end)
end)
