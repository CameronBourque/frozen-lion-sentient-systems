local FakeGame = require("FakeGame")
local Game = require("Game")

local BUDDHISM = { type = "RELIGION_BUDDHISM", name = "Buddhism", beliefs = { "BELIEF_TITHE", "BELIEF_FEED_THE_WORLD" }, holyCity = 65536 }

-- Returns the religion section JSON for player 0, in a world with the players given.
local function ReligionWith(players)
	local env = Game.new()

	FakeGame.Install(env, { players = players, beliefs = { { type = "BELIEF_GOD_OF_THE_SEA" } }, pantheonFaith = 12 })
	Game.run(env, "Scripts/State/SentientSystemsCore_State.lua")

	return env.SentientSystems_GetState(0):match("\"religion\":(%b{})")
end

-- Returns a city with the ID, religions, and majority given.
local function City(id, religions, majority)
	return { id = id, name = "LOC_CITY_NAME_" .. id, x = 0, y = id % 10, population = 5, religions = religions, majority = majority }
end

describe("SentientSystems_GetReligionState", function()
	it("gives the faith the next pantheon needs, before the player has one", function()
		assert.equal("{\"pantheonFaith\":12}", ReligionWith({ [0] = {} }))
	end)

	it("gives the pantheon, and whether the player has a Great Prophet before their first belief", function()
		assert.equal("{\"pantheon\":\"BELIEF_GOD_OF_THE_SEA\",\"prophet\":false}", ReligionWith({ [0] = { pantheon = "BELIEF_GOD_OF_THE_SEA" } }))
		assert.equal("{\"pantheon\":\"BELIEF_GOD_OF_THE_SEA\",\"prophet\":true}", ReligionWith({ [0] = { pantheon = "BELIEF_GOD_OF_THE_SEA", prophet = true } }))
	end)

	it("leaves out the prophet once the player has earned a belief", function()
		local religion = { type = "RELIGION_BUDDHISM", name = "Buddhism", holyCity = 65536 }

		assert.falsy(ReligionWith({ [0] = { pantheon = "BELIEF_GOD_OF_THE_SEA", religion = religion, beliefsEarned = 1, cities = { City(65536) } } }):find("prophet", 1, true))
	end)

	it("gives the founded religion with its beliefs, holy city, majority, and the cities that follow it", function()
		local players = {
			[0] = {
				pantheon = "BELIEF_GOD_OF_THE_SEA",
				religion = BUDDHISM,
				cities = {
					City(65536, { { type = "RELIGION_BUDDHISM", followers = 5 } }, "RELIGION_BUDDHISM"),
					City(131072, { { type = "RELIGION_BUDDHISM", followers = 0 } }),
				},
			},
			[1] = { cities = { City(65536, { { type = "RELIGION_HINDUISM", followers = 3 }, { type = "RELIGION_BUDDHISM", followers = 1 } }, "RELIGION_HINDUISM") } },
		}

		assert.equal(
			"{\"founded\":{\"beliefs\":[\"BELIEF_TITHE\",\"BELIEF_FEED_THE_WORLD\"],\"cities\":[{\"city\":65536,\"followers\":5,\"owner\":0},"
				.. "{\"city\":65536,\"followers\":1,\"owner\":1}],\"holyCity\":65536,\"majority\":1,\"name\":\"Buddhism\",\"type\":\"RELIGION_BUDDHISM\"},"
				.. "\"pantheon\":\"BELIEF_GOD_OF_THE_SEA\"}",
			ReligionWith(players)
		)
	end)

	it("leaves out the holy city once no city holds it", function()
		local religion = { type = "RELIGION_BUDDHISM", name = "Buddhism", beliefs = {}, holyCity = 7 }

		assert.falsy(ReligionWith({ [0] = { pantheon = "BELIEF_GOD_OF_THE_SEA", religion = religion } }):find("holyCity", 1, true))
	end)
end)
