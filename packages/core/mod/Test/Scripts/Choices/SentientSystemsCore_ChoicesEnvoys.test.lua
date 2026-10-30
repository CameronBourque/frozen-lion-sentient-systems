local FakeGame = require("FakeGame")
local Game = require("Game")

-- Returns a city-state that can receive envoys.
local function CityState(name)
	return { minor = { name = name, leader = "LEADER_MINOR_CIV_" .. name } }
end

-- Returns the envoy choice JSON for player 0, whose data is given, or nil when it is left out.
local function EnvoysWith(player)
	local env = Game.new()
	local freeCities = CityState("FREE_CITIES")

	freeCities.minor.cantReceive = true
	FakeGame.Install(env, { players = { [0] = player, [12] = CityState("SAMARKAND"), [13] = CityState("CAHOKIA"), [14] = CityState("GRANADA"), [62] = freeCities } })
	Game.run(env, "Scripts/Choices/SentientSystemsCore_Choices.lua")

	return env.SentientSystems_GetChoices(0):match("\"envoys\":(%b{})")
end

describe("SentientSystems_GetEnvoyChoices", function()
	it("lists the met city-states the player isn't at war with, in the game's order", function()
		assert.equal(
			"{\"cityStates\":[12,14],\"tokens\":2}",
			EnvoysWith({ influence = { tokens = 2 }, met = { 12, 13, 14, 62 }, atWar = { 13 } })
		)
	end)

	it("is left out without tokens, or while the player can't send them", function()
		assert.is_nil(EnvoysWith({ met = { 12 } }))
		assert.is_nil(EnvoysWith({ influence = { tokens = 1, canGive = false }, met = { 12 } }))
	end)

	it("is left out when no city-state can take an envoy", function()
		assert.is_nil(EnvoysWith({ influence = { tokens = 1 }, met = { 62 } }))
	end)
end)
