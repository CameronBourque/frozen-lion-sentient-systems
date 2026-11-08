local FakeGame = require("FakeGame")
local Game = require("Game")
local Helpers = require("Helpers")

local Failed, With = Helpers.Failed, Helpers.With

local KNIGHT = { id = 7405612, type = "UNIT_KNIGHT", x = 20, y = 20, moves = 4 }
local SPEC_OPS = { id = 7405612, type = "UNIT_SPEC_OPS", x = 20, y = 20, moves = 3, paradrop = true }

-- Runs the action for the unit in a fake game where player 0 has only it.
local function Run(unit, action, x, y)
	local env = Game.new()

	FakeGame.Install(env, { players = { [0] = { units = { unit } } } })
	Game.run(env, "Scripts/Actions/SentientSystemsCore_Actions.lua")

	return env.SentientSystems_UnitAction(0, unit.id, action, x, y), env
end

-- The tiles the game lists for an action, nearest first.
local TILES = { { x = 22, y = 20 }, { x = 21, y = 20 } }

describe("airlift", function()
	local READY = With(KNIGHT, { canNow = { "airlift" }, airTargets = { airlift = TILES } })

	it("requests the command with the tile", function()
		local result, env = Run(READY, "airlift", 22, 20)

		assert.equal("{\"ok\":true}", result)
		assert.same({
			{
				unit = KNIGHT.id,
				command = env.UnitCommandTypes.AIRLIFT,
				parameters = { [env.UnitCommandTypes.PARAM_X] = 22, [env.UnitCommandTypes.PARAM_Y] = 20 },
			},
		}, env.requests)
	end)

	it("fails for a ship and an air unit", function()
		local ship = With(READY, { type = "UNIT_FRIGATE", domain = "DOMAIN_SEA" })
		local plane = With(READY, { type = "UNIT_JET_FIGHTER", domain = "DOMAIN_AIR" })

		assert.equal(Failed("This kind of unit can't airlift."), (Run(ship, "airlift", 22, 20)))
		assert.equal(Failed("This kind of unit can't airlift."), (Run(plane, "airlift", 22, 20)))
	end)

	it("says the unit has no moves left", function()
		assert.equal(Failed("The unit has no moves left."), (Run(With(READY, { moves = 0 }), "airlift", 22, 20)))
	end)

	it("says what an airlift needs when the game lists no tile", function()
		assert.equal(Failed("An airlift needs the unit on or next to a city or aerodrome with an airport, and another to land in."), (Run(KNIGHT, "airlift", 22, 20)))
	end)

	it("lists the tiles for one that isn't listed", function()
		assert.equal(Failed("That tile isn't one the unit can airlift to. The nearest that are (21, 20), (22, 20)."), (Run(READY, "airlift", 5, 5)))
	end)

	it("fails when the game lists the tile but won't start it", function()
		assert.equal(Failed("The game won't start that airlift."), (Run(With(READY, { canNow = {} }), "airlift", 22, 20)))
	end)
end)

describe("paradrop", function()
	local READY = With(SPEC_OPS, { canNow = { "paradrop" }, airTargets = { paradrop = TILES } })

	it("requests the command with the tile", function()
		local result, env = Run(READY, "paradrop", 21, 20)

		assert.equal("{\"ok\":true}", result)
		assert.equal(env.UnitCommandTypes.PARADROP, env.requests[1].command)
	end)

	it("fails for a unit without the ability", function()
		assert.equal(Failed("This kind of unit can't paradrop."), (Run(With(KNIGHT, { airTargets = { paradrop = TILES } }), "paradrop", 21, 20)))
	end)

	it("says the unit has to start in a city or on an airstrip", function()
		assert.equal(Failed("The unit has to start in a city or on an airstrip to paradrop."), (Run(SPEC_OPS, "paradrop", 21, 20)))
	end)

	it("lists the tiles for one that isn't listed", function()
		assert.equal(Failed("That tile isn't one the unit can paradrop to. The nearest that are (21, 20), (22, 20)."), (Run(READY, "paradrop", 5, 5)))
	end)
end)
