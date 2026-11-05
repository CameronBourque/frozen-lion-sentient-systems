local FakeGame = require("FakeGame")
local Game = require("Game")

local FIGHTER = { id = 7405612, type = "UNIT_JET_FIGHTER", domain = "DOMAIN_AIR", x = 20, y = 20, moves = 10 }
local KNIGHT = { id = 7405612, type = "UNIT_KNIGHT", x = 20, y = 20, moves = 4 }
local SPEC_OPS = { id = 7405612, type = "UNIT_SPEC_OPS", x = 20, y = 20, moves = 3, paradrop = true }

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

local function Failed(reason)
	return "{\"ok\":false,\"reason\":\"" .. reason .. "\"}"
end

-- Runs the action for the unit in a fake game where player 0 has only it.
local function Run(unit, action, x, y)
	local env = Game.new()

	FakeGame.Install(env, { players = { [0] = { units = { unit } } } })
	Game.run(env, "Scripts/Actions/SentientSystemsCore_Actions.lua")

	return env.SentientSystems_UnitAction(0, unit.id, action, x, y), env
end

-- The tiles the game lists for an action, nearest first.
local TILES = { { x = 22, y = 20 }, { x = 21, y = 20 } }

describe("rebase and deploy", function()
	local READY = With(FIGHTER, { canNow = { "rebase", "deploy" }, airTargets = { rebase = TILES, deploy = TILES } })

	it("requests the operation with the tile", function()
		for _, action in ipairs({ "rebase", "deploy" }) do
			local result, env = Run(READY, action, 21, 20)

			assert.equal("{\"ok\":true}", result)
			assert.same({
				{
					unit = FIGHTER.id,
					operation = env.UnitOperationTypes[action:upper()],
					parameters = { [env.UnitOperationTypes.PARAM_X] = 21, [env.UnitOperationTypes.PARAM_Y] = 20 },
				},
			}, env.requests)
		end
	end)

	it("fails for a tile off the map", function()
		assert.equal(Failed("The tile (-1, 4) is off the map."), (Run(READY, "rebase", -1, 4)))
	end)

	it("fails for a unit that isn't an air unit", function()
		assert.equal(Failed("This kind of unit can't rebase."), (Run(With(KNIGHT, { airTargets = { rebase = TILES } }), "rebase", 21, 20)))
	end)

	it("needs moves to rebase and none to deploy", function()
		local still = With(READY, { moves = 0 })

		assert.equal(Failed("The unit has no moves left."), (Run(still, "rebase", 21, 20)))
		assert.equal("{\"ok\":true}", (Run(still, "deploy", 21, 20)))
	end)

	it("says the game lists no tile", function()
		assert.equal(Failed("The unit has no tile in range to rebase to."), (Run(With(FIGHTER, { canNow = {} }), "rebase", 21, 20)))
		assert.equal(Failed("The unit has no tile in range to deploy to."), (Run(With(FIGHTER, { canNow = {} }), "deploy", 21, 20)))
	end)

	it("lists the nearest tiles for one that isn't listed", function()
		assert.equal(Failed("That tile isn't one the unit can rebase to. The nearest that are (21, 20), (22, 20)."), (Run(READY, "rebase", 30, 30)))
	end)

	it("gives a count after the first tiles", function()
		local many = {}

		for i = 1, 10 do
			many[i] = { x = 20 + i, y = 20 }
		end

		local unit = With(READY, { airTargets = { rebase = many } })
		local reason = "That tile isn't one the unit can rebase to. The nearest that are (21, 20), (22, 20), (23, 20), (24, 20), (25, 20), (26, 20), (27, 20), (28, 20), and 2 more."

		assert.equal(Failed(reason), (Run(unit, "rebase", 40, 40)))
	end)

	it("fails when the game lists the tile but won't start it", function()
		assert.equal(Failed("The game won't start that rebase."), (Run(With(FIGHTER, { airTargets = { rebase = TILES } }), "rebase", 21, 20)))
	end)
end)

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

	it("fails for a ship", function()
		local ship = With(READY, { type = "UNIT_FRIGATE", domain = "DOMAIN_SEA" })

		assert.equal(Failed("This kind of unit can't airlift."), (Run(ship, "airlift", 22, 20)))
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
