local FakeGame = require("FakeGame")
local Game = require("Game")
local Helpers = require("Helpers")

local Failed = Helpers.Failed

-- Player 0 has 2 envoys, has met Samarkand and Cahokia, and is at war with
-- Cahokia. Valletta is unmet, and the Free Cities can't take envoys.
local PLAYER = { influence = { tokens = 2 }, met = { 12, 13 }, atWar = { 13 } }

-- Returns an environment with the actions loaded into a fake game where player
-- 0 has the data given, or PLAYER.
local function Load(player)
	local env = Game.new()
	local players = {
		[0] = player or PLAYER,
		[12] = { minor = { name = "Samarkand" } },
		[13] = { minor = { name = "Cahokia" } },
		[14] = { minor = { name = "Valletta" } },
		[62] = { minor = { name = "Free Cities", cantReceive = true } },
	}

	FakeGame.Install(env, { players = players })
	Game.run(env, "Scripts/Actions/SentientSystemsCore_Actions.lua")

	return env
end

-- Returns the requests the screen sends for count envoys to the city-state.
local function Requests(env, cityState, count)
	local P = env.PlayerOperations
	local requests = {}

	for i = 1, count do
		requests[i] = { player = 0, operation = P.GIVE_INFLUENCE_TOKEN, parameters = { [P.PARAM_PLAYER_ONE] = cityState } }
	end

	return requests
end

describe("SentientSystems_SendEnvoys", function()
	it("sends the screen's request once for each envoy, one when the count is left out", function()
		local env = Load()

		assert.equal("{\"ok\":true}", env.SentientSystems_SendEnvoys(0, 12))
		assert.same(Requests(env, 12, 1), env.requests)

		env = Load()

		assert.equal("{\"ok\":true}", env.SentientSystems_SendEnvoys(0, 12, 2))
		assert.same(Requests(env, 12, 2), env.requests)
	end)

	it("fails for a count of envoys the player can't send", function()
		local cases = {
			{ { influence = { tokens = 0 }, met = { 12 } }, 1, "You have no envoys to send. The envoys choice lists city-states once you do." },
			{ { influence = { tokens = 2, canGive = false }, met = { 12 } }, 1, "You have no envoys to send. The envoys choice lists city-states once you do." },
			{ PLAYER, 3, "You have 2 envoys to send, not 3." },
			{ PLAYER, 0, "Send a whole number of envoys, at least 1, not 0." },
			{ PLAYER, 1.5, "Send a whole number of envoys, at least 1, not 1.5." },
			{ PLAYER, "2", "Send a whole number of envoys, at least 1, not 2." },
		}

		for _, case in ipairs(cases) do
			local env = Load(case[1])

			assert.equal(Failed(case[3]), env.SentientSystems_SendEnvoys(0, 12, case[2]))
			assert.same({}, env.requests)
		end
	end)

	it("fails for a city-state the screen turns off", function()
		local cases = {
			{ 0, "Player 0 isn't a city-state. Use an ID from the envoys choice." },
			{ 99, "Player 99 isn't a city-state. Use an ID from the envoys choice." },
			{ "12", "Player 12 isn't a city-state. Use an ID from the envoys choice." },
			{ 62, "Player 62 isn't a city-state. Use an ID from the envoys choice." },
			{ 14, "You haven't met city-state 14. Use an ID from the envoys choice." },
			{ 13, "You are at war with Cahokia. Make peace first." },
		}

		for _, case in ipairs(cases) do
			local env = Load()

			assert.equal(Failed(case[2]), env.SentientSystems_SendEnvoys(0, case[1]))
			assert.same({}, env.requests)
		end
	end)

	it("fails for an ID with no player", function()
		assert.equal(Failed("SendEnvoys failed: no player 3"), Load().SentientSystems_SendEnvoys(3, 12))
	end)
end)
