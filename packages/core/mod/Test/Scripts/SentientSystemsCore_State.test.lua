local FakeGame = require("FakeGame")
local Game = require("Game")

-- The yields JSON for a city with every yield at 0.
local NO_YIELDS = "\"yields\":{\"culture\":0,\"faith\":0,\"food\":0,\"gold\":0,\"production\":0,\"science\":0}"

local ROME = { id = 65536, name = "LOC_CITY_NAME_ROME", x = 17, y = 14, population = 3 }

-- Returns an environment with the state script loaded into a fake game built from world.
local function Load(world)
	local env = Game.new()

	FakeGame.Install(env, world)
	Game.run(env, "Scripts/SentientSystemsCore_State.lua")

	return env
end

-- Returns a copy of city with the fields in changes.
local function With(city, changes)
	local copy = {}

	for key, value in pairs(city) do
		copy[key] = value
	end

	for key, value in pairs(changes) do
		copy[key] = value
	end

	return copy
end

describe("SentientSystems_GetState", function()
	it("lists each city's ID, name, position, and population", function()
		local env = Load({
			players = { [0] = { cities = { ROME, { id = 131072, name = "LOC_CITY_NAME_ANTIUM", x = 20, y = 10, population = 1 } } } },
			text = { LOC_CITY_NAME_ROME = "Rome", LOC_CITY_NAME_ANTIUM = "Antium" },
		})

		assert.equal(
			"{\"cities\":[{\"id\":65536,\"name\":\"Rome\",\"population\":3,\"x\":17,\"y\":14," .. NO_YIELDS .. "},"
				.. "{\"id\":131072,\"name\":\"Antium\",\"population\":1,\"x\":20,\"y\":10," .. NO_YIELDS .. "}]}",
			env.SentientSystems_GetState(0)
		)
	end)

	it("lists only the given player's cities", function()
		local env = Load({
			players = { [0] = { cities = { ROME } }, [1] = { cities = { { id = 65537, name = "Uruk", x = 10, y = 10, population = 5 } } } },
		})

		assert.equal("{\"cities\":[{\"id\":65537,\"name\":\"Uruk\",\"population\":5,\"x\":10,\"y\":10," .. NO_YIELDS .. "}]}", env.SentientSystems_GetState(1))
	end)

	it("gives an empty list for a player with no cities", function()
		local env = Load({ players = { [0] = {} } })

		assert.equal("{\"cities\":[]}", env.SentientSystems_GetState(0))
	end)

	it("escapes a city name with quotes", function()
		local env = Load({ players = { [0] = { cities = { With(ROME, { name = "The \"Big\" City" }) } } } })

		assert.truthy(env.SentientSystems_GetState(0):find("\"name\":\"The \\\"Big\\\" City\"", 1, true))
	end)

	it("adds the current production with its turns left", function()
		local env = Load({ players = { [0] = { cities = { With(ROME, { production = { type = "UNIT_SLINGER", turnsLeft = 2 } }) } } } })

		assert.truthy(env.SentientSystems_GetState(0):find("\"production\":{\"turnsLeft\":2,\"type\":\"UNIT_SLINGER\"}", 1, true))
	end)

	it("leaves out production when the city produces nothing", function()
		local env = Load({ players = { [0] = { cities = { ROME } } } })

		assert.is_nil(env.SentientSystems_GetState(0):find("production\":{", 1, true))
	end)

	it("leaves out the type of a production that GameInfo.Types doesn't know", function()
		local env = Load({ players = { [0] = { cities = { With(ROME, { production = { hash = 77, turnsLeft = 3 } }) } } } })

		assert.truthy(env.SentientSystems_GetState(0):find("\"production\":{\"turnsLeft\":3}", 1, true))
	end)

	it("adds each yield, rounded down to one decimal place as the city panel shows it", function()
		local env = Load({
			players = { [0] = { cities = { With(ROME, {
				yields = { FOOD = 9, PRODUCTION = 6, GOLD = -2.55, SCIENCE = 3.5, CULTURE = 3.8984375, FAITH = 0 },
			}) } } },
		})

		assert.truthy(env.SentientSystems_GetState(0):find(
			"\"yields\":{\"culture\":3.8,\"faith\":0,\"food\":9,\"gold\":-2.6,\"production\":6,\"science\":3.5}", 1, true))
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

-- Returns player 0's first city.
local function FirstCity(env)
	for _, city in env.Players[0]:GetCities():Members() do
		return city
	end
end

describe("FakeGame", function()
	it("raises an error for turns left on a production the city doesn't have", function()
		local env = Load({ players = { [0] = { cities = { With(ROME, { production = { type = "UNIT_SLINGER", turnsLeft = 2 } }) } } } })
		local city = FirstCity(env)

		assert.has_error(function()
			city:GetBuildQueue():GetTurnsLeft("UNIT_SCOUT")
		end)
	end)

	it("raises an error for a yield type the game doesn't have", function()
		local env = Load({ players = { [0] = { cities = { ROME } } } })
		local city = FirstCity(env)

		assert.has_error(function()
			city:GetYield(99)
		end, "no yield type 99")
	end)
end)
