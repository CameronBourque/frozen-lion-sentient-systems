local FakeGame = require("FakeGame")
local Game = require("Game")

-- Returns the player section JSON for player 0, whose data is given, with or without Gathering
-- Storm.
local function PlayerWith(data, expansion2)
	local env = Game.new()

	FakeGame.Install(env, { expansion2 = expansion2, players = { [0] = data } })
	Game.run(env, "Scripts/State/SentientSystemsCore_State.lua")

	return env.SentientSystems_GetState(0):match("\"player\":(%b{})")
end

describe("SentientSystems_GetPlayerState", function()
	it("gives the balances and the yields per turn as the top bar shows them", function()
		assert.equal(
			"{\"culture\":216.6,\"faith\":{\"balance\":2357,\"perTurn\":109},\"favor\":{\"balance\":335,\"perTurn\":3},"
				.. "\"gold\":{\"balance\":9610,\"perTurn\":265.1},\"science\":123.5,\"tourism\":92,"
				.. "\"tradeRoutes\":{\"active\":17,\"capacity\":20}}",
			PlayerWith({
				gold = 9610.84375,
				goldPerTurn = 475.08203125,
				upkeep = 210,
				faith = 2357.01171875,
				faithPerTurn = 109,
				science = 123.50390625,
				culture = 216.62109375,
				tourism = 92,
				favor = 335,
				favorPerTurn = 3,
				trade = { active = 17, capacity = 20 },
			}, true)
		)
	end)

	it("gives a negative gold income when the upkeep is more than the income", function()
		local json = PlayerWith({ goldPerTurn = 10, upkeep = 14.3 })

		assert.truthy(json:find("\"gold\":{\"balance\":0,\"perTurn\":-4.3}", 1, true))
	end)

	it("leaves out the trade routes while the capacity is 0", function()
		assert.falsy(PlayerWith({ trade = { active = 0, capacity = 0 } }):find("tradeRoutes", 1, true))
	end)

	it("leaves out favor without Gathering Storm", function()
		assert.falsy(PlayerWith({ favor = 5 }):find("favor", 1, true))
	end)
end)
