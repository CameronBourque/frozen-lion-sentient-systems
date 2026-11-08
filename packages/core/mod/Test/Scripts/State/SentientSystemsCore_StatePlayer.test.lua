local FakeGame = require("FakeGame")
local Game = require("Game")

-- Returns the player section JSON for player 0, whose data is given, with or
-- without Gathering Storm, without its income and resources, which have tests
-- of their own.
local function PlayerWith(data, expansion2)
	local env = Game.new()

	FakeGame.Install(env, { expansion2 = expansion2, players = { [0] = data } })
	Game.run(env, "Scripts/State/SentientSystemsCore_State.lua")

	return (env.SentientSystems_GetState(0):match("\"player\":(%b{})"):gsub("\"income\":%b{},", ""):gsub("\"resources\":%b[],", ""))
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

describe("SentientSystems_GetDealItems", function()
	it("gives each item of the type with an amount that is negative when the player gives it", function()
		local env = Game.new()
		local deals = {
			{ player = 4, gold = 5, duration = 30, enacted = 70, outgoing = true },
			{ player = 4, gold = 3, duration = 30, enacted = 73 },
			{ player = 4, gold = 9, duration = 0, enacted = 73 },
			{ player = 4, resource = "RESOURCE_TURTLES", amount = 2, duration = 30, enacted = 70 },
		}

		FakeGame.Install(env, { turn = 85, players = { [0] = { deals = deals }, [4] = {} } })
		Game.run(env, "Scripts/State/SentientSystemsCore_State.lua")

		local list = {}

		for i, entry in ipairs(env.SentientSystems_GetDealItems(0, env.DealItemTypes.GOLD)) do
			list[i] = { player = entry.player, turnsLeft = entry.turnsLeft, amount = entry.amount }
		end

		assert.same({ { player = 4, turnsLeft = 15, amount = -5 }, { player = 4, turnsLeft = 18, amount = 3 } }, list)
	end)
end)
