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
			"{\"cities\":[],\"units\":[{\"health\":{\"max\":100,\"value\":100},\"id\":196608,\"moves\":{\"left\":3,\"max\":3},"
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
		assert.equal("{\"cities\":[],\"units\":[]}", StateWith({ With(SCOUT, { x = -9999, y = -9999 }) }))
	end)

	it("skips a unit that is dead or about to die", function()
		assert.equal("{\"cities\":[],\"units\":[]}", StateWith({ With(SCOUT, { dead = true }), With(SCOUT, { id = 2, delayedDeath = true }) }))
	end)

	it("lists more than one unit, in the game's order", function()
		local state = StateWith({ SCOUT, { id = 131073, type = "UNIT_WARRIOR", x = 7, y = 13, moves = 2, maxMoves = 2 } })

		assert.truthy(state:find("UNIT_SCOUT.*UNIT_WARRIOR"))
	end)
end)
