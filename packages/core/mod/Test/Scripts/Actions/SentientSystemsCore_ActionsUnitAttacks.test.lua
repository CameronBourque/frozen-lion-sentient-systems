local FakeGame = require("FakeGame")
local Game = require("Game")
local Helpers = require("Helpers")

local Failed, With = Helpers.Failed, Helpers.With

-- A knight at (20, 20) with a melee strength, an attack left, and moves.
local KNIGHT = { id = 6160397, type = "UNIT_KNIGHT", x = 20, y = 20, moves = 2, combat = 50, attacks = 1, paths = { { x = 21, y = 20 } } }

-- A crossbowman that is stronger at range, with two tiles in range, and a
-- target on one.
local CROSSBOW = {
	id = 4456460,
	type = "UNIT_CROSSBOWMAN",
	x = 20,
	y = 20,
	moves = 2,
	combat = 30,
	ranged = 40,
	attacks = 1,
	targets = { { x = 22, y = 20, target = true }, { x = 21, y = 20, target = false } },
}

-- Returns an environment with the actions loaded into a fake game that has
-- player 0 with the unit, who sees the tiles, and player 4 with the units.
local function Load(unit, visible, rivals, cities)
	local env = Game.new()
	local world = { players = { [0] = { units = { unit }, visible = visible or { { 21, 20 }, { 22, 20 } } } } }

	if rivals ~= nil or cities ~= nil then
		world.players[4] = { units = rivals or {}, cities = cities or {}, visible = {} }
	end

	FakeGame.Install(env, world)
	Game.run(env, "Scripts/Actions/SentientSystemsCore_Actions.lua")

	return env
end

local function Rival(x, y, changes)
	return With({ id = 1, type = "UNIT_BUILDER", x = x, y = y }, changes or {})
end

-- A ship with a ranged strength, a target in range at (22, 20), and a land tile
-- at (21, 20) that it can raid.
local SUBMARINE = With(CROSSBOW, { id = 16056482, type = "UNIT_NUCLEAR_SUBMARINE", domain = "DOMAIN_SEA", combat = 80, ranged = 85, raidTiles = { { x = 21, y = 20 } } })

-- A ship that is stronger in melee, with the same land tile to raid.
local PRIVATEER = With(KNIGHT, { id = 16056483, type = "UNIT_PRIVATEER", domain = "DOMAIN_SEA", raidTiles = { { x = 21, y = 20 } } })

describe("a coastal raid", function()
	local function Raid(env, unit, x, y)
		local types = env.UnitOperationTypes

		return { { unit = unit.id, operation = types.COASTAL_RAID, parameters = { [types.PARAM_X] = x, [types.PARAM_Y] = y } } }
	end

	it("is what a ranged ship's attack on a raid tile becomes", function()
		local env = Load(SUBMARINE)

		assert.equal("{\"ok\":true}", env.SentientSystems_UnitAction(0, SUBMARINE.id, "attack", 21, 20))
		assert.same(Raid(env, SUBMARINE, 21, 20), env.requests)
	end)

	it("is what a melee ship's attack on a raid tile becomes, with no move", function()
		local env = Load(PRIVATEER)

		assert.equal("{\"ok\":true}", env.SentientSystems_UnitAction(0, PRIVATEER.id, "attack", 21, 20))
		assert.same(Raid(env, PRIVATEER, 21, 20), env.requests)
	end)

	it("leaves a target in range to the ranged attack", function()
		local env = Load(SUBMARINE)

		assert.equal("{\"ok\":true}", env.SentientSystems_UnitAction(0, SUBMARINE.id, "attack", 22, 20))
		assert.equal(env.UnitOperationTypes.RANGE_ATTACK, env.requests[1].operation)
	end)

	it("fails when the game won't start it", function()
		local env = Load(With(SUBMARINE, { blocked = true }))

		assert.equal(Failed("The game won't start that raid."), env.SentientSystems_UnitAction(0, SUBMARINE.id, "attack", 21, 20))
	end)

	it("lists the raid tiles when a tile is neither a target nor a raid tile", function()
		local ranged = Load(With(SUBMARINE, { targets = { { x = 22, y = 20, target = true } } }), { { 22, 20 }, { 23, 20 } })
		local melee = Load(PRIVATEER, { { 21, 20 }, { 23, 20 } }, { Rival(23, 20) })

		assert.equal(Failed("That tile isn't a target. The targets in range are (22, 20). A coastal raid can hit (21, 20)."), ranged.SentientSystems_UnitAction(0, SUBMARINE.id, "attack", 23, 20))
		assert.equal(Failed("A melee unit attacks an adjacent tile. Move next to it first. A coastal raid can hit (21, 20)."), melee.SentientSystems_UnitAction(0, PRIVATEER.id, "attack", 23, 20))
	end)

	it("is for ships only", function()
		local env = Load(With(KNIGHT, { raidTiles = { { x = 21, y = 20 } } }), nil, { Rival(21, 20) })

		assert.equal("{\"ok\":true}", env.SentientSystems_UnitAction(0, KNIGHT.id, "attack", 21, 20))
		assert.equal(env.UnitOperationTypes.MOVE_TO, env.requests[1].operation)
	end)
end)

describe("attack", function()
	it("fails for a unit with no strength", function()
		assert.equal(Failed("This kind of unit can't attack."), Load(With(KNIGHT, { combat = 0 })).SentientSystems_UnitAction(0, KNIGHT.id, "attack", 21, 20))
	end)

	it("fails without a tile, off the map, or on a tile the player can't see", function()
		local env = Load(KNIGHT)

		assert.equal(Failed("An attack needs the tile to hit."), env.SentientSystems_UnitAction(0, KNIGHT.id, "attack"))
		assert.equal(Failed("The tile (-1, 4) is off the map."), env.SentientSystems_UnitAction(0, KNIGHT.id, "attack", -1, 4))
		assert.equal(Failed("You can't see that tile."), env.SentientSystems_UnitAction(0, KNIGHT.id, "attack", 21, 21))
	end)

	it("fails for a unit with no attacks left", function()
		assert.equal(Failed("The unit has no attacks left."), Load(With(KNIGHT, { attacks = 0 })).SentientSystems_UnitAction(0, KNIGHT.id, "attack", 21, 20))
	end)

	it("fails for an attack that would start a war", function()
		local env = Load(With(KNIGHT, { startsWar = { { x = 21, y = 20, player = 4 } } }), { { 21, 20 } }, { Rival(21, 20) })

		assert.equal(Failed("Attacking there would start a war with player 4."), env.SentientSystems_UnitAction(0, KNIGHT.id, "attack", 21, 20))
		assert.same({}, env.requests)
	end)

	describe("in melee", function()
		it("moves into an adjacent tile with an enemy unit, with the attack modifier", function()
			local env = Load(KNIGHT, nil, { Rival(21, 20, { hidden = false }) })
			local M = env.UnitOperationMoveModifiers

			assert.equal("{\"ok\":true}", env.SentientSystems_UnitAction(0, KNIGHT.id, "attack", 21, 20))
			assert.same({ {
				unit = KNIGHT.id,
				operation = env.UnitOperationTypes.MOVE_TO,
				parameters = {
					[env.UnitOperationTypes.PARAM_X] = 21,
					[env.UnitOperationTypes.PARAM_Y] = 20,
					[env.UnitOperationTypes.PARAM_MODIFIERS] = M.ATTACK + M.MOVE_IGNORE_UNEXPLORED_DESTINATION,
				},
			} }, env.requests)
		end)

		it("lets a religious unit attack a religious unit of a player it is at peace with", function()
			local inquisitor = With(KNIGHT, { type = "UNIT_INQUISITOR", combat = 0, religiousStrength = 75 })
			local env = Load(inquisitor, nil, { Rival(21, 20, { type = "UNIT_MISSIONARY", religiousStrength = 100 }) })

			assert.equal("{\"ok\":true}", env.SentientSystems_UnitAction(0, KNIGHT.id, "attack", 21, 20))
			assert.equal(env.UnitOperationTypes.MOVE_TO, env.requests[1].operation)
		end)

		it("attacks a city of another player", function()
			local env = Load(KNIGHT, nil, nil, { { id = 1, name = "LOC_CITY_NAME_ROME", x = 21, y = 20 } })

			assert.equal("{\"ok\":true}", env.SentientSystems_UnitAction(0, KNIGHT.id, "attack", 21, 20))
		end)

		it("fails for a tile that isn't adjacent", function()
			local env = Load(KNIGHT, { { 22, 20 } }, { Rival(22, 20) })

			assert.equal(Failed("A melee unit attacks an adjacent tile. Move next to it first."), env.SentientSystems_UnitAction(0, KNIGHT.id, "attack", 22, 20))
		end)

		it("fails for a unit with no moves left", function()
			assert.equal(Failed("The unit has no moves left."), Load(With(KNIGHT, { moves = 0 }), nil, { Rival(21, 20) }).SentientSystems_UnitAction(0, KNIGHT.id, "attack", 21, 20))
		end)

		it("fails for a tile with nothing to attack, or a unit the player doesn't see", function()
			assert.equal(Failed("There is nothing to attack on that tile."), Load(KNIGHT).SentientSystems_UnitAction(0, KNIGHT.id, "attack", 21, 20))
			assert.equal(Failed("There is nothing to attack on that tile."), Load(KNIGHT, nil, { Rival(21, 20, { hidden = true }) }).SentientSystems_UnitAction(0, KNIGHT.id, "attack", 21, 20))
		end)

		it("fails when the game won't start the attack", function()
			local env = Load(With(KNIGHT, { blocked = true }), nil, { Rival(21, 20) })

			assert.equal(Failed("The game won't start that attack."), env.SentientSystems_UnitAction(0, KNIGHT.id, "attack", 21, 20))
		end)
	end)

	describe("at range", function()
		it("shoots at a target in range", function()
			local env = Load(CROSSBOW)

			assert.equal("{\"ok\":true}", env.SentientSystems_UnitAction(0, CROSSBOW.id, "attack", 22, 20))
			assert.same({ { unit = CROSSBOW.id, operation = env.UnitOperationTypes.RANGE_ATTACK, parameters = { [env.UnitOperationTypes.PARAM_X] = 22, [env.UnitOperationTypes.PARAM_Y] = 20 } } }, env.requests)
		end)

		it("shoots with bombard strength too", function()
			assert.equal("{\"ok\":true}", Load(With(CROSSBOW, { ranged = 0, bombard = 55 })).SentientSystems_UnitAction(0, CROSSBOW.id, "attack", 22, 20))
		end)

		it("fails for a tile that isn't a target, and lists the targets", function()
			local env = Load(CROSSBOW)

			assert.equal(Failed("That tile isn't a target. The targets in range are (22, 20)."), env.SentientSystems_UnitAction(0, CROSSBOW.id, "attack", 21, 20))
			assert.same({}, env.requests)
		end)

		it("fails with nothing in range", function()
			assert.equal(Failed("That tile isn't a target, and nothing is in range."), Load(With(CROSSBOW, { targets = {} })).SentientSystems_UnitAction(0, CROSSBOW.id, "attack", 22, 20))
		end)

		it("counts the targets past the first eight", function()
			local targets = {}

			for x = 1, 10 do
				targets[x] = { x = x, y = 5, target = true }
			end

			assert.equal(Failed("That tile isn't a target. The targets in range are (1, 5), (2, 5), (3, 5), (4, 5), (5, 5), (6, 5), (7, 5), (8, 5), and 2 more."), Load(With(CROSSBOW, { targets = targets })).SentientSystems_UnitAction(0, CROSSBOW.id, "attack", 22, 20))
		end)

		it("fails when the game won't start the attack", function()
			assert.equal(Failed("The game won't start that attack."), Load(With(CROSSBOW, { blocked = true })).SentientSystems_UnitAction(0, CROSSBOW.id, "attack", 22, 20))
		end)
	end)

	describe("in the air", function()
		local BOMBER = With(CROSSBOW, { type = "UNIT_JET_BOMBER", domain = "DOMAIN_AIR", combat = 90, ranged = 0, bombard = 120 })

		it("flies at a target in range", function()
			local env = Load(BOMBER)

			assert.equal("{\"ok\":true}", env.SentientSystems_UnitAction(0, BOMBER.id, "attack", 22, 20))
			assert.equal(env.UnitOperationTypes.AIR_ATTACK, env.requests[1].operation)
		end)

		it("lists the targets for a tile that isn't one", function()
			assert.equal(Failed("That tile isn't a target. The targets in range are (22, 20)."), Load(BOMBER).SentientSystems_UnitAction(0, BOMBER.id, "attack", 21, 20))
		end)
	end)
end)

describe("priority_target", function()
	local TILES = { { x = 22, y = 20, target = true }, { x = 21, y = 20, target = false } }
	local READY = With(CROSSBOW, { canNow = { "priority_target" }, airTargets = { priority_target = TILES } })

	local function Run(unit, x, y)
		local env = Load(unit)

		return env.SentientSystems_UnitAction(0, unit.id, "priority_target", x, y), env
	end

	it("requests the command with the tile of an escort", function()
		local result, env = Run(READY, 22, 20)

		assert.equal("{\"ok\":true}", result)
		assert.same({
			{
				unit = CROSSBOW.id,
				command = env.UnitCommandTypes.PRIORITY_TARGET,
				parameters = { [env.UnitCommandTypes.PARAM_X] = 22, [env.UnitCommandTypes.PARAM_Y] = 20 },
			},
		}, env.requests)
	end)

	it("says the unit has no moves left", function()
		assert.equal(Failed("The unit has no moves left."), (Run(With(READY, { moves = 0 }), 22, 20)))
	end)

	it("says no tile has a unit to pick out", function()
		local none = With(READY, { airTargets = { priority_target = { { x = 21, y = 20, target = false } } } })
		local reason = "No tile in range has a unit to pick out. Only some units, such as spec ops and air units, can pick a priority target."

		assert.equal(Failed(reason), (Run(none, 22, 20)))
	end)

	it("lists the tiles that have one for another tile", function()
		assert.equal(Failed("That tile isn't one the unit can pick a priority target on. The nearest that are (22, 20)."), (Run(READY, 21, 20)))
	end)

	it("fails when the game lists the tile but won't start it", function()
		assert.equal(Failed("The game won't start that priority target."), (Run(With(READY, { canNow = {} }), 22, 20)))
	end)
end)
