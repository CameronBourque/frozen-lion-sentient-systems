local FakeGame = require("FakeGame")
local Game = require("Game")

local ADUATUCA = { id = 65536, name = "LOC_CITY_NAME_ADUATUCA", x = 42, y = 49, population = 1 }

-- Returns an environment with the state script loaded into a fake game built from world.
local function Load(world)
	local env = Game.new()

	FakeGame.Install(env, world)
	Game.run(env, "Scripts/SentientSystemsCore_State.lua")

	return env
end

describe("SentientSystems_GetState", function()
	it("lists each city's ID, name, position, and population", function()
		local env = Load({
			players = { [0] = { cities = { ADUATUCA, { id = 131072, name = "LOC_CITY_NAME_ALESIA", x = 40, y = 45, population = 3 } } } },
			text = { LOC_CITY_NAME_ADUATUCA = "Aduatuca", LOC_CITY_NAME_ALESIA = "Alesia" },
		})

		assert.equal(
			"{\"cities\":[{\"id\":65536,\"name\":\"Aduatuca\",\"population\":1,\"x\":42,\"y\":49},"
				.. "{\"id\":131072,\"name\":\"Alesia\",\"population\":3,\"x\":40,\"y\":45}]}",
			env.SentientSystems_GetState(0)
		)
	end)

	it("lists only the given player's cities", function()
		local env = Load({
			players = { [0] = { cities = { ADUATUCA } }, [1] = { cities = { { id = 65537, name = "Rome", x = 10, y = 10, population = 5 } } } },
		})

		assert.equal("{\"cities\":[{\"id\":65537,\"name\":\"Rome\",\"population\":5,\"x\":10,\"y\":10}]}", env.SentientSystems_GetState(1))
	end)

	it("gives an empty list for a player with no cities", function()
		local env = Load({ players = { [0] = {} } })

		assert.equal("{\"cities\":[]}", env.SentientSystems_GetState(0))
	end)

	it("escapes a city name with quotes", function()
		local env = Load({ players = { [0] = { cities = { { id = 1, name = "The \"Big\" City", x = 0, y = 0, population = 1 } } } } })

		assert.equal("{\"cities\":[{\"id\":1,\"name\":\"The \\\"Big\\\" City\",\"population\":1,\"x\":0,\"y\":0}]}", env.SentientSystems_GetState(0))
	end)

	it("raises an error for an ID with no player", function()
		local env = Load({ players = { [0] = {} } })

		assert.has_error(function()
			env.SentientSystems_GetState(5)
		end, "no player 5")
	end)

	it("loads the JSON encoder, so the bridge can stash the state", function()
		local env = Load({ players = { [0] = {} } })

		assert.equal(1, env.SentientSystems_Stash(env.SentientSystems_GetState(0)))
	end)
end)
