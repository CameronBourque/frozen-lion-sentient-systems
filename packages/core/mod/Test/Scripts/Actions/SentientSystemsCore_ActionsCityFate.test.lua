local FakeGame = require("FakeGame")
local Game = require("Game")
local Helpers = require("Helpers")

local Failed = Helpers.Failed

-- A city of player 1's, so a player that keeps it isn't wiped out.
local OTHER_CITY = { id = 65536, name = "Uruk", x = 10, y = 10, population = 3 }
local CAPTURED = { id = 131073, name = "Caguana", x = 47, y = 40, population = 1, originalOwner = 1, ownerBefore = 1, conqueredFrom = 1 }
local REBELLED = { id = 589832, name = "Stockholm", x = 47, y = 27, population = 1 }
local NO_CITY = "You have no city to decide. The cityFates choice lists one once you capture a city or one rebels to join you."

-- Returns an environment with the actions loaded, where player 0's data is
-- given, and players 1 and 2 have a city each.
local function Load(player)
	local env = Game.new()

	FakeGame.Install(env, {
		players = { [0] = player, [1] = { cities = { OTHER_CITY } }, [2] = { cities = { { id = 65537, name = "Ur", x = 3, y = 3, population = 2 } } } },
	})
	Game.run(env, "Scripts/Actions/SentientSystemsCore_Actions.lua")

	return env
end

-- Returns the request the screens send for the city and the directive.
local function Request(env, cityID, directive)
	return { {
		city = cityID,
		command = env.CityCommandTypes.DESTROY,
		parameters = { [env.UnitOperationTypes.PARAM_FLAGS] = env.CityDestroyDirectives[directive] },
	} }
end

describe("SentientSystems_DecideCity", function()
	it("sends the raze screen's request to keep or raze a captured city", function()
		for _, directive in ipairs({ "KEEP", "RAZE" }) do
			local env = Load({ captured = CAPTURED })

			assert.equal("{\"ok\":true}", env.SentientSystems_DecideCity(0, 131073, directive))
			assert.same(Request(env, 131073, directive), env.requests)
		end
	end)

	it("sends the request to liberate a captured city the screen offers to liberate", function()
		local env = Load({ captured = Helpers.With(CAPTURED, { originalOwner = 2, conqueredFrom = 3 }), liberate = { 1, 2 } })

		assert.equal("{\"ok\":true}", env.SentientSystems_DecideCity(0, 131073, "LIBERATE_FOUNDER"))
		assert.same(Request(env, 131073, "LIBERATE_FOUNDER"), env.requests)
	end)

	it("sends the disloyal city screen's request to keep or refuse a rebelled city", function()
		for _, directive in ipairs({ "KEEP", "REJECT" }) do
			local env = Load({ captured = CAPTURED, rebelled = REBELLED })

			assert.equal("{\"ok\":true}", env.SentientSystems_DecideCity(0, 589832, directive))
			assert.same(Request(env, 589832, directive), env.requests)
		end
	end)

	it("fails for a directive the screen doesn't offer", function()
		local cases = {
			{ { captured = CAPTURED }, 131073, "REJECT", "REJECT isn't an option for Caguana. Use one of KEEP, RAZE." },
			{ { captured = CAPTURED }, 131073, "LIBERATE_FOUNDER", "LIBERATE_FOUNDER isn't an option for Caguana. Use one of KEEP, RAZE." },
			{ { rebelled = REBELLED }, 589832, "RAZE", "RAZE isn't an option for Stockholm. Use one of KEEP, REJECT." },
			{ { rebelled = REBELLED }, 589832, 2, "2 isn't an option for Stockholm. Use one of KEEP, REJECT." },
		}

		for _, case in ipairs(cases) do
			local env = Load(case[1])

			assert.equal(Failed(case[4]), env.SentientSystems_DecideCity(0, case[2], case[3]))
			assert.same({}, env.requests)
		end
	end)

	it("fails to raze a city the player can't raze, with the screen's reason", function()
		local env = Load({ captured = Helpers.With(CAPTURED, { canRaze = false }) })

		assert.equal(Failed("LOC_RAZE_CITY_RAZE_DISABLED_EXPLANATION"), env.SentientSystems_DecideCity(0, 131073, "RAZE"))
		assert.same({}, env.requests)
	end)

	it("fails for a city that isn't waiting, or with none waiting", function()
		local env = Load({ captured = CAPTURED, rebelled = REBELLED })

		assert.equal(
			Failed("City 65536 isn't waiting for a decision. Use a city from the cityFates choice: 131073, 589832."),
			env.SentientSystems_DecideCity(0, 65536, "KEEP")
		)
		assert.equal(Failed(NO_CITY), Load({}).SentientSystems_DecideCity(0, 131073, "KEEP"))
		assert.same({}, env.requests)
	end)

	it("fails for an ID with no player", function()
		assert.equal(Failed("DecideCity failed: no player 3"), Load({ captured = CAPTURED }).SentientSystems_DecideCity(3, 131073, "KEEP"))
	end)
end)
