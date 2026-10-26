local FakeGame = require("FakeGame")
local Game = require("Game")

-- Returns an environment with the choices script loaded into a fake game built from world.
local function Load(world)
	local env = Game.new()

	FakeGame.Install(env, world)
	Game.run(env, "Scripts/Choices/SentientSystemsCore_Choices.lua")

	return env
end

describe("SentientSystems_GetChoices", function()
	it("gives each choice for a player with no cities", function()
		assert.equal("{\"production\":[]}", Load({ players = { [0] = {} } }).SentientSystems_GetChoices(0))
	end)

	it("raises an error for an ID with no player", function()
		local env = Load({ players = { [0] = {} } })

		assert.has_error(function()
			env.SentientSystems_GetChoices(5)
		end, "no player 5")
	end)

	it("loads the JSON encoder and each choice without an ERROR line, so the bridge can stash the choices", function()
		local env = Load({ players = { [0] = {} } })

		assert.same({}, env.printed)
		assert.is_function(env.SentientSystems_GetProductionChoices)
		assert.equal(1, env.SentientSystems_Stash(env.SentientSystems_GetChoices(0)))
	end)
end)
