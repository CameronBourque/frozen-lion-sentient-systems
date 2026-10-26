local FakeGame = require("FakeGame")
local Game = require("Game")

local SCOUT = { id = 196608, type = "UNIT_SCOUT", x = 24, y = 15, moves = 3, maxMoves = 3 }

-- Returns the state JSON for player 0 with the given units.
local function StateWith(units)
	local env = Game.new()

	FakeGame.Install(env, { players = { [0] = { units = units } } })
	Game.run(env, "Scripts/State/SentientSystemsCore_State.lua")

	return env.SentientSystems_GetState(0)
end

-- Returns a copy of unit with the fields in changes.
local function With(unit, changes)
	local copy = {}

	for key, value in pairs(unit) do
		copy[key] = value
	end

	for key, value in pairs(changes) do
		copy[key] = value
	end

	return copy
end

describe("SentientSystems_GetUnitStates", function()
	it("lists each unit's ID, type, position, moves, and health", function()
		assert.equal(
			"{\"blockers\":{\"list\":[],\"units\":[]},\"cities\":[],\"religion\":{\"pantheonFaith\":25},\"rivals\":{\"cities\":[],\"units\":[]},\"tiles\":[],\"units\":[{\"health\":{\"max\":100,\"value\":100},\"id\":196608,\"moves\":{\"left\":3,\"max\":3},"
				.. "\"type\":\"UNIT_SCOUT\",\"x\":24,\"y\":15}]}",
			StateWith({ SCOUT })
		)
	end)

	it("gives health as the most damage less the damage taken", function()
		local state = StateWith({ With(SCOUT, { damage = 35, moves = 1 }) })

		assert.truthy(state:find("\"health\":{\"max\":100,\"value\":65}", 1, true))
		assert.truthy(state:find("\"moves\":{\"left\":1,\"max\":3}", 1, true))
	end)

	it("skips a unit that isn't on the map", function()
		assert.equal("{\"blockers\":{\"list\":[],\"units\":[]},\"cities\":[],\"religion\":{\"pantheonFaith\":25},\"rivals\":{\"cities\":[],\"units\":[]},\"tiles\":[],\"units\":[]}", StateWith({ With(SCOUT, { x = -9999, y = -9999 }) }))
	end)

	it("skips a unit that is dead or about to die", function()
		assert.equal("{\"blockers\":{\"list\":[],\"units\":[]},\"cities\":[],\"religion\":{\"pantheonFaith\":25},\"rivals\":{\"cities\":[],\"units\":[]},\"tiles\":[],\"units\":[]}", StateWith({ With(SCOUT, { dead = true }), With(SCOUT, { id = 2, delayedDeath = true }) }))
	end)

	it("adds the unit's experience and its promotions", function()
		local state = StateWith({ With(SCOUT, {
			experience = { points = 20, nextLevel = 45, promotions = { "PROMOTION_RANGER" } },
		}) })

		assert.truthy(state:find("\"availablePromotions\":[],\"experience\":{\"nextLevel\":45,\"points\":20}", 1, true))
		assert.truthy(state:find("\"promotions\":[\"PROMOTION_RANGER\"]", 1, true))
	end)

	it("adds the promotions the unit can pick now", function()
		local state = StateWith({ With(SCOUT, {
			experience = { points = 15, nextLevel = 15, available = { "PROMOTION_RANGER", "PROMOTION_ALPINE" } },
		}) })

		assert.truthy(state:find("\"availablePromotions\":[\"PROMOTION_RANGER\",\"PROMOTION_ALPINE\"]", 1, true))
	end)

	it("leaves out experience and promotions for a unit with no experience", function()
		local state = StateWith({ SCOUT })

		assert.is_nil(state:find("experience", 1, true))
		assert.is_nil(state:find("romotions", 1, true))
	end)

	it("lists more than one unit, in the game's order", function()
		local state = StateWith({ SCOUT, { id = 131073, type = "UNIT_WARRIOR", x = 7, y = 13, moves = 2, maxMoves = 2 } })

		assert.truthy(state:find("UNIT_SCOUT.*UNIT_WARRIOR"))
	end)
end)

describe("SentientSystems_GetHealth", function()
	-- Returns an environment with the state script loaded, where the helper lives.
	local function Load()
		local env = Game.new()

		FakeGame.Install(env, {})
		Game.run(env, "Scripts/State/SentientSystemsCore_State.lua")

		return env
	end

	it("gives the most damage less the damage taken, out of the most damage", function()
		assert.same({ value = 65, max = 100 }, Load().SentientSystems_GetHealth(100, 35))
	end)

	it("gives full health when no damage is taken", function()
		assert.same({ value = 200, max = 200 }, Load().SentientSystems_GetHealth(200, 0))
	end)
end)
