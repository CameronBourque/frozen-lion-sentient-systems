local FakeGame = require("FakeGame")
local Game = require("Game")

local env

before_each(function()
	env = Game.new()
	FakeGame.Install(env, { players = { [0] = { cities = { { id = 65536, x = 20, y = 20, name = "LOC_CITY_NAME_ROME" } } } }, text = { LOC_CITY_NAME_ROME = "Rome" } })
	Game.run(env, "Scripts/SentientSystemsCore_Lookups.lua")
end)

describe("SentientSystems_GetPlayer", function()
	it("returns the player", function()
		assert.equal(0, env.SentientSystems_GetPlayer(0):GetID())
	end)

	it("raises an error for an ID with no player", function()
		assert.has_error(function()
			env.SentientSystems_GetPlayer(7)
		end, "no player 7")
	end)
end)

describe("SentientSystems_GetCityRef", function()
	it("returns the city's owner, ID, and name", function()
		assert.same({ owner = 0, id = 65536, name = "Rome" }, env.SentientSystems_GetCityRef(env.SentientSystems_FindCity(0, 65536)))
	end)

	it("returns nil with no city", function()
		assert.is_nil(env.SentientSystems_GetCityRef(nil))
	end)
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

describe("SentientSystems_GetPosition", function()
	it("returns the plot's x and y", function()
		local plot = {
			GetX = function()
				return 12
			end,
			GetY = function()
				return 30
			end,
		}

		assert.same({ x = 12, y = 30 }, env.SentientSystems_GetPosition(plot))
	end)
end)
