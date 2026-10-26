local FakeGame = require("FakeGame")
local Game = require("Game")

-- Returns a city-state with the ID's name, the leader given, the envoys by player ID, and the
-- suzerain.
local function CityState(name, inherit, envoys, suzerain)
	return { minor = { name = "LOC_CIVILIZATION_" .. name .. "_NAME", leader = "LEADER_MINOR_CIV_" .. name, inherit = inherit, envoys = envoys, suzerain = suzerain } }
end

-- Returns the envoys section JSON for player 0, in a world with the players given.
local function EnvoysWith(players)
	local env = Game.new()

	FakeGame.Install(env, { players = players, text = { LOC_CIVILIZATION_SAMARKAND_NAME = "Samarkand" } })
	Game.run(env, "Scripts/State/SentientSystemsCore_State.lua")

	return env.SentientSystems_GetState(0):match("\"envoys\":(%b{})")
end

describe("SentientSystems_GetEnvoyState", function()
	it("gives the envoy tokens and influence, with no city-states met", function()
		assert.equal(
			"{\"cityStates\":[],\"influence\":{\"envoys\":2,\"perTurn\":3,\"points\":40,\"threshold\":100},\"tokens\":1}",
			EnvoysWith({ [0] = { influence = { tokens = 1, points = 40, perTurn = 3, threshold = 100, envoys = 2 } } })
		)
	end)

	it("lists each met city-state with its kind, the player's envoys, and the envoys to be suzerain", function()
		local players = {
			[0] = { met = { 1, 12, 13 } },
			[1] = { met = { 0 } },
			[12] = CityState("SAMARKAND", "LEADER_MINOR_CIV_TRADE", { [0] = 2, [1] = 3 }, 1),
			[13] = CityState("SCIENTIFIC", nil, { [0] = 1 }),
			[14] = CityState("KUMASI", "LEADER_MINOR_CIV_TRADE", { [1] = 1 }),
		}

		assert.equal(
			"{\"cityStates\":[{\"envoys\":2,\"name\":\"Samarkand\",\"player\":12,\"suzerain\":1,\"suzerainNeeds\":4,\"type\":\"TRADE\"},"
				.. "{\"envoys\":1,\"name\":\"LOC_CIVILIZATION_SCIENTIFIC_NAME\",\"player\":13,\"suzerainNeeds\":3,\"type\":\"SCIENTIFIC\"}],"
				.. "\"influence\":{\"envoys\":1,\"perTurn\":0,\"points\":0,\"threshold\":50},\"tokens\":0}",
			EnvoysWith(players)
		)
	end)

	it("needs only the player's own envoys while they are suzerain", function()
		local players = {
			[0] = { met = { 12 } },
			[12] = CityState("SAMARKAND", "LEADER_MINOR_CIV_TRADE", { [0] = 4 }, 0),
		}

		assert.truthy(EnvoysWith(players):find("\"suzerain\":0,\"suzerainNeeds\":4,", 1, true))
	end)

	it("hides a suzerain the player hasn't met", function()
		local players = {
			[0] = { met = { 12 } },
			[12] = CityState("SAMARKAND", "LEADER_MINOR_CIV_TRADE", { [2] = 3 }, 2),
		}

		assert.truthy(EnvoysWith(players):find("\"suzerainNeeds\":4,\"suzerainUnmet\":true,", 1, true))
	end)

	it("leaves out the kind of a leader with none, and the Free Cities", function()
		local freeCities = CityState("FREE_CITIES")

		freeCities.minor.cantReceive = true

		local players = {
			[0] = { met = { 12, 62 } },
			[12] = CityState("SAMARKAND", "LEADER_MINOR_CIV_DEFAULT", {}),
			[62] = freeCities,
		}

		assert.equal(
			"{\"cityStates\":[{\"envoys\":0,\"name\":\"Samarkand\",\"player\":12,\"suzerainNeeds\":3}],"
				.. "\"influence\":{\"envoys\":1,\"perTurn\":0,\"points\":0,\"threshold\":50},\"tokens\":0}",
			EnvoysWith(players)
		)
	end)
end)
