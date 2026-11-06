local FakeGame = require("FakeGame")
local Game = require("Game")

-- A city at x, y with the data it adds.
local function City(id, name, x, y, extra)
	local city = { id = id, name = name, x = x, y = y, population = 5 }

	for key, value in pairs(extra or {}) do
		city[key] = value
	end

	return city
end

-- A route from the city of the first player and ID to the second, with the
-- gold each end receives.
local function Route(from, to, origin, destination)
	return {
		from = from,
		to = to,
		origin = { route = { GOLD = origin } },
		destination = { route = { GOLD = destination } },
	}
end

-- Returns the trade section JSON for player 0. Player 0 has two cities, player
-- 1 one and player 2 one, each with the routes given.
local function TradeWith(routes, potential)
	local env = Game.new()

	FakeGame.Install(env, {
		players = {
			[0] = { cities = { City(1, "Home", 10, 10, { routes = routes[0] }), City(2, "Own", 13, 10) } },
			[1] = { cities = { City(1, "Foreign", 30, 10, { routes = routes[1] }) } },
			[2] = { cities = { City(1, "Third", 40, 10, { routes = routes[2] }) } },
		},
		routes = potential,
	})
	Game.run(env, "Scripts/State/SentientSystemsCore_State.lua")

	return env.SentientSystems_GetState(0):match("\"trade\":(%b{})")
end

describe("SentientSystems_GetTradeState", function()
	it("lists the player's routes, those to their own cities first, and the routes of others that end in them", function()
		local json = TradeWith({
			[0] = {
				{ player = 2, id = 1, trader = 201 },
				{ player = 0, id = 2, trader = 200 },
			},
			[1] = { { player = 0, id = 1, trader = 300 } },
			[2] = { { player = 1, id = 1, trader = 301 } },
		}, {
			Route({ 0, 1 }, { 0, 2 }, 2, 1),
			Route({ 0, 1 }, { 2, 1 }, 3, 1),
			Route({ 1, 1 }, { 0, 1 }, 4, 5),
		})

		assert.equal(
			"{\"incoming\":[{\"destination\":{\"id\":1,\"name\":\"Home\",\"owner\":0},\"origin\":{\"id\":1,\"name\":\"Foreign\",\"owner\":1},"
				.. "\"pathBonus\":false,\"trader\":300,\"yields\":{\"destination\":{\"yields\":[{\"amount\":5,\"type\":\"YIELD_GOLD\"}]},"
				.. "\"origin\":{\"yields\":[{\"amount\":4,\"type\":\"YIELD_GOLD\"}]}}}],"
				.. "\"outgoing\":[{\"destination\":{\"id\":2,\"name\":\"Own\",\"owner\":0},\"origin\":{\"id\":1,\"name\":\"Home\",\"owner\":0},"
				.. "\"pathBonus\":false,\"trader\":200,\"yields\":{\"destination\":{\"yields\":[{\"amount\":1,\"type\":\"YIELD_GOLD\"}]},"
				.. "\"origin\":{\"yields\":[{\"amount\":2,\"type\":\"YIELD_GOLD\"}]}}},"
				.. "{\"destination\":{\"id\":1,\"name\":\"Third\",\"owner\":2},\"origin\":{\"id\":1,\"name\":\"Home\",\"owner\":0},"
				.. "\"pathBonus\":false,\"trader\":201,\"yields\":{\"destination\":{\"yields\":[{\"amount\":1,\"type\":\"YIELD_GOLD\"}]},"
				.. "\"origin\":{\"yields\":[{\"amount\":3,\"type\":\"YIELD_GOLD\"}]}}}]}",
			json
		)
	end)

	it("leaves out the routes of others that end in someone else's city", function()
		local json = TradeWith({ [2] = { { player = 1, id = 1, trader = 301 } } }, { Route({ 2, 1 }, { 1, 1 }, 1, 1) })

		assert.equal("{\"incoming\":[],\"outgoing\":[]}", json)
	end)

	it("is empty before any route is made", function()
		assert.equal("{\"incoming\":[],\"outgoing\":[]}", TradeWith({}, {}))
	end)
end)
