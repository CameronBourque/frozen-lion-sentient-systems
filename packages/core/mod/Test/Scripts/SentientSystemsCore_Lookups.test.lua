local FakeGame = require("FakeGame")
local Game = require("Game")

local env

before_each(function()
	env = Game.new()
	FakeGame.Install(env, { players = { [0] = { cities = { { id = 65536, x = 20, y = 20 } } } } })
	Game.run(env, "Scripts/SentientSystemsCore_Lookups.lua")
end)

describe("SentientSystems_FindCity", function()
	it("returns the city of the player", function()
		local city, failure = env.SentientSystems_FindCity(0, 65536)

		assert.equal(65536, city:GetID())
		assert.is_nil(failure)
	end)

	it("returns why for a city the player doesn't have, and for no player", function()
		assert.same({ nil, "Player 0 has no city 9." }, { env.SentientSystems_FindCity(0, 9) })
		assert.same({ nil, "Player 7 has no city 1." }, { env.SentientSystems_FindCity(7, 1) })
		assert.same({ nil, "Player nil has no city nil." }, { env.SentientSystems_FindCity(nil, nil) })
	end)
end)
