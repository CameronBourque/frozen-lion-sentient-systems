local FakeGame = require("FakeGame")
local Game = require("Game")

-- A city of player 0 at x, y, with the data it adds.
local function City(id, name, x, y, extra)
	local city = { id = id, name = name, x = x, y = y, population = 5 }

	for key, value in pairs(extra or {}) do
		city[key] = value
	end

	return city
end

-- A trader of player 0 that can start routes to the cities in tradeTo, as
-- player and id.
local function Trader(id, x, y, tradeTo)
	return { id = id, type = "UNIT_TRADER", x = x, y = y, trader = true, tradeTo = tradeTo }
end

-- A potential route from player 0's city 1 to the city of a player, with the
-- yields of each end.
local function Route(to, path, origin, destination)
	return { from = { 0, 1 }, to = to, path = path, origin = origin, destination = destination or {} }
end

-- A city-state with a trade route quest for player 0 and a city at 30, 10.
local FOREIGN = {
	minor = { name = "FOREIGN", leader = "LEADER_MINOR_CIV_FOREIGN", quests = { [0] = { { type = "QUEST_SEND_TRADE_ROUTE", name = "Send a route" } } } },
	cities = { City(1, "Foreign", 30, 10) },
	trade = { multipliers = { GOLD = 2 } },
}

-- Returns the trade route choice JSON for player 0, or nil when it is left out.
local function ChoicesWith(player, routes)
	local env = Game.new()

	FakeGame.Install(env, {
		players = { [0] = player, [1] = FOREIGN },
		routes = routes,
		-- Index 0, the first religion row, means no religion to the game.
		religions = { { type = "RELIGION_NONE" }, { type = "RELIGION_SHINTO" } },
		text = { LOC_UNIT_TRADER_NAME = "Trader" },
	})
	Game.run(env, "Scripts/Choices/SentientSystemsCore_Choices.lua")

	return env.SentientSystems_GetChoices(0):match("\"tradeRoutes\":(%b[])")
end

local HOME = City(1, "Home", 10, 10, { majority = "RELIGION_SHINTO", routes = { { player = 0, id = 2, trader = 101 } } })
local OWN = City(2, "Own", 13, 10, { tradingPosts = { 0 } })
local FAR = City(3, "Far", 40, 10)
local NEAR = City(4, "Near", 11, 10)

describe("SentientSystems_GetTradeRouteChoices", function()
	it("lists the cities an idle trader can start a route to, the player's own first, with what each end receives", function()
		local trader = Trader(100, 10, 10, { { player = 0, id = 2 }, { player = 0, id = 3 }, { player = 1, id = 1 } })

		assert.equal(
			"[{\"city\":{\"id\":1,\"name\":\"Home\",\"owner\":0},\"destinations\":["
				.. "{\"destination\":{\"yields\":[]},\"distance\":3,\"id\":2,\"name\":\"Own\","
				.. "\"origin\":{\"pressure\":{\"amount\":0.5,\"religion\":\"RELIGION_SHINTO\"},"
				.. "\"yields\":[{\"amount\":1,\"type\":\"YIELD_FOOD\"},{\"amount\":3,\"type\":\"YIELD_GOLD\"}]},"
				.. "\"owner\":0,\"pathBonus\":true,\"tradingPost\":true},"
				.. "{\"destination\":{\"pressure\":{\"amount\":1,\"religion\":\"RELIGION_SHINTO\"},\"yields\":[{\"amount\":3,\"type\":\"YIELD_GOLD\"}]},"
				.. "\"distance\":20,\"id\":1,\"name\":\"Foreign\","
				.. "\"origin\":{\"yields\":[{\"amount\":2.9,\"type\":\"YIELD_GOLD\"},{\"amount\":1,\"type\":\"YIELD_FAITH\"}]},"
				.. "\"owner\":1,\"pathBonus\":false,\"quest\":\"Send a route\",\"tradingPost\":false}],"
				.. "\"name\":\"Trader\",\"unit\":100}]",
			ChoicesWith({
				cities = { HOME, OWN, FAR, NEAR },
				units = { trader },
				trade = { multipliers = { GOLD = 1.25 } },
			}, {
				Route({ 0, 2 }, 3, { route = { FOOD = 1 }, path = { GOLD = 2 }, modifiers = { GOLD = 1 }, pressure = 0.5 }),
				Route({ 1, 1 }, 5, { route = { GOLD = 2.33 }, modifiers = { FAITH = 1 } }, { route = { GOLD = 1.5 }, pressure = 1 }),
			})
		)
	end)

	it("leaves out a city with no path, and a city the game won't let the trader reach", function()
		local result = ChoicesWith({
			cities = { HOME, OWN, FAR, NEAR },
			units = { Trader(100, 10, 10, { { player = 0, id = 3 } }) },
		}, {})

		assert.truthy(result:find("\"destinations\":[],", 1, true))
	end)

	it("leaves out a trader that has a route, one outside a city, and a unit that isn't a trader", function()
		assert.is_nil(ChoicesWith({
			cities = { HOME, OWN },
			units = {
				Trader(101, 10, 10, { { player = 0, id = 2 } }),
				Trader(102, 20, 20, { { player = 0, id = 2 } }),
				{ id = 103, type = "UNIT_BUILDER", x = 10, y = 10 },
			},
		}, {}))
	end)

	it("is left out with no units", function()
		assert.is_nil(ChoicesWith({ cities = { HOME } }, {}))
	end)
end)
