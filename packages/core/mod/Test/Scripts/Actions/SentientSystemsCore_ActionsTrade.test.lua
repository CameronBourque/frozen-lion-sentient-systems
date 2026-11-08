local FakeGame = require("FakeGame")
local Game = require("Game")
local Helpers = require("Helpers")

local Failed, With = Helpers.Failed, Helpers.With

local HOME = { id = 1, name = "Home", x = 10, y = 10, population = 5, routes = {} }
local OWN = { id = 2, name = "Own", x = 13, y = 10, population = 5 }
local FOREIGN = { minor = { name = "FOREIGN", leader = "LEADER_MINOR_CIV_FOREIGN" }, cities = { { id = 1, name = "Foreign", x = 30, y = 10, population = 5 } } }
local TRADER = { id = 100, type = "UNIT_TRADER", x = 10, y = 10, trader = true, tradeTo = { { player = 0, id = 2 }, { player = 1, id = 1 } } }

-- Returns an environment with the actions loaded into a fake game where
-- player 0 has the unit, a home city, and an own city, with room for routes
-- unless the trade data says otherwise. Routes lists the potential routes.
local function Load(unit, trade, home, routes)
	local env = Game.new()

	FakeGame.Install(env, {
		players = {
			[0] = { units = { unit }, cities = { home or HOME, OWN }, trade = trade or { active = 0, capacity = 2 } },
			[1] = FOREIGN,
		},
		routes = routes or { { from = { 0, 1 }, to = { 0, 2 }, path = 3 }, { from = { 0, 1 }, to = { 1, 1 }, path = 20 } },
	})
	Game.run(env, "Scripts/Actions/SentientSystemsCore_Actions.lua")

	return env
end

describe("SentientSystems_TradeRoute", function()
	it("requests a route to a city of the player and to one of another player, from the trader's city", function()
		for _, destination in ipairs({ { 0, 2, 13 }, { 1, 1, 30 } }) do
			local env = Load(TRADER)
			local types = env.UnitOperationTypes

			assert.equal("{\"ok\":true}", env.SentientSystems_TradeRoute(0, 100, destination[1], destination[2]))
			assert.same({
				{
					unit = 100,
					operation = types.MAKE_TRADE_ROUTE,
					parameters = {
						[types.PARAM_X0] = destination[3],
						[types.PARAM_Y0] = 10,
						[types.PARAM_X1] = 10,
						[types.PARAM_Y1] = 10,
					},
				},
			}, env.requests)
		end
	end)

	it("fails for a unit that doesn't exist", function()
		assert.equal(Failed("Player 0 has no unit 5."), Load(TRADER).SentientSystems_TradeRoute(0, 5, 0, 2))
	end)

	it("fails for a unit that isn't a trader", function()
		local knight = { id = 100, type = "UNIT_KNIGHT", x = 10, y = 10 }

		assert.equal(Failed("This kind of unit can't make trade routes."), Load(knight).SentientSystems_TradeRoute(0, 100, 0, 2))
	end)

	it("fails for a trader that already has a route", function()
		local busy = With(HOME, { routes = { { player = 0, id = 2, trader = 100 } } })

		assert.equal(Failed("The trader already has a route."), Load(TRADER, nil, busy).SentientSystems_TradeRoute(0, 100, 0, 2))
	end)

	it("fails for a trader outside a city", function()
		local env = Load(With(TRADER, { x = 11 }))

		assert.equal(Failed("A trader starts a route from a city. Move it into one first."), env.SentientSystems_TradeRoute(0, 100, 0, 2))
		assert.same({}, env.requests)
	end)

	it("fails when the player has no free route slot", function()
		local env = Load(TRADER, { active = 2, capacity = 2 })

		assert.equal(Failed("The player has no free trade route slot."), env.SentientSystems_TradeRoute(0, 100, 0, 2))
		assert.same({}, env.requests)
	end)

	it("fails for a city that doesn't exist", function()
		local env = Load(TRADER)

		assert.equal(Failed("Player 0 has no city 9."), env.SentientSystems_TradeRoute(0, 100, 0, 9))
		assert.equal(Failed("Player 7 has no city 1."), env.SentientSystems_TradeRoute(0, 100, 7, 1))
		assert.equal(Failed("Player nil has no city nil."), env.SentientSystems_TradeRoute(0, 100, nil, nil))
	end)

	it("fails for a city the game doesn't allow, or one with no path", function()
		local reason = Failed("The trader can't reach Foreign. Pick a city from its destinations in the trade route choices.")
		local refused = With(TRADER, { tradeTo = { { player = 0, id = 2 } } })

		assert.equal(reason, Load(refused).SentientSystems_TradeRoute(0, 100, 1, 1))
		assert.equal(reason, Load(TRADER, nil, nil, {}).SentientSystems_TradeRoute(0, 100, 1, 1))
	end)
end)
