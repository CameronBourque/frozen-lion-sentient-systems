local FakeGame = require("FakeGame")
local Game = require("Game")
local Helpers = require("Helpers")

local Failed, With = Helpers.Failed, Helpers.With

local SCOUT = { id = 196608, type = "UNIT_SCOUT", x = 10, y = 10, moves = 3, paths = { { x = 11, y = 10 }, { x = 40, y = 40 } } }

-- Returns an environment with the actions loaded into a fake game that has
-- player 0 with the unit, who sees the given tiles.
local function Load(unit, visible)
	local env = Game.new()

	FakeGame.Install(env, { players = { [0] = { units = { unit }, visible = visible } } })
	Game.run(env, "Scripts/Actions/SentientSystemsCore_Actions.lua")

	return env
end

describe("SentientSystems_MoveUnit", function()
	it("requests a move to a tile with a route, without the attack modifier", function()
		local env = Load(SCOUT)

		assert.equal("{\"ok\":true}", env.SentientSystems_MoveUnit(0, SCOUT.id, 11, 10))
		assert.same({ {
			unit = SCOUT.id,
			operation = env.UnitOperationTypes.MOVE_TO,
			parameters = {
				[env.UnitOperationTypes.PARAM_X] = 11,
				[env.UnitOperationTypes.PARAM_Y] = 10,
				[env.UnitOperationTypes.PARAM_MODIFIERS] = env.UnitOperationMoveModifiers.MOVE_IGNORE_UNEXPLORED_DESTINATION,
			},
		} }, env.requests)
	end)

	it("moves over more than one turn when the game has a route", function()
		local env = Load(SCOUT)

		assert.equal("{\"ok\":true}", env.SentientSystems_MoveUnit(0, SCOUT.id, 40, 40))
		assert.equal(1, #env.requests)
	end)

	it("fails for a unit the player doesn't have", function()
		local env = Load(SCOUT)

		assert.equal(Failed("Player 0 has no unit 5."), env.SentientSystems_MoveUnit(0, 5, 11, 10))
		assert.equal(Failed("Player 3 has no unit 5."), env.SentientSystems_MoveUnit(3, 5, 11, 10))
		assert.same({}, env.requests)
	end)

	it("fails for a tile off the map", function()
		local env = Load(SCOUT)

		assert.equal(Failed("The tile (-1, 4) is off the map."), env.SentientSystems_MoveUnit(0, SCOUT.id, -1, 4))
		assert.equal(Failed("The tile (5, 100) is off the map."), env.SentientSystems_MoveUnit(0, SCOUT.id, 5, 100))
	end)

	it("fails for the unit's own tile", function()
		assert.equal(Failed("The unit is already on that tile."), Load(SCOUT).SentientSystems_MoveUnit(0, SCOUT.id, 10, 10))
	end)

	it("fails for an air unit", function()
		local env = Load(With(SCOUT, { type = "UNIT_BOMBER", domain = "DOMAIN_AIR" }))

		assert.equal(Failed("Air units can't move. They rebase, deploy, or attack instead."), env.SentientSystems_MoveUnit(0, SCOUT.id, 11, 10))
	end)

	it("fails for a unit with no moves left", function()
		assert.equal(Failed("The unit has no moves left."), Load(With(SCOUT, { moves = 0 })).SentientSystems_MoveUnit(0, SCOUT.id, 11, 10))
	end)

	it("fails for a move that starts a war on a visible tile", function()
		local unit = With(SCOUT, { startsWar = { { x = 11, y = 10, player = 4 } } })
		local env = Load(unit, { { 11, 10 } })

		assert.equal(Failed("Moving there would start a war with player 4."), env.SentientSystems_MoveUnit(0, SCOUT.id, 11, 10))
		assert.same({}, env.requests)
	end)

	it("doesn't check for war on a tile the player can't see, as the game doesn't", function()
		local env = Load(With(SCOUT, { startsWar = { { x = 11, y = 10, player = 4 } } }))

		assert.equal("{\"ok\":true}", env.SentientSystems_MoveUnit(0, SCOUT.id, 11, 10))
	end)

	it("moves on a visible tile where no war starts", function()
		assert.equal("{\"ok\":true}", Load(SCOUT, { { 11, 10 } }).SentientSystems_MoveUnit(0, SCOUT.id, 11, 10))
	end)

	it("fails for a tile with no route", function()
		local env = Load(SCOUT)

		assert.equal(Failed("The unit has no route to that tile."), env.SentientSystems_MoveUnit(0, SCOUT.id, 12, 10))
		assert.same({}, env.requests)
	end)

	it("fails when the game won't start the move", function()
		local env = Load(With(SCOUT, { blocked = true }))

		assert.equal(Failed("The game won't start that move."), env.SentientSystems_MoveUnit(0, SCOUT.id, 11, 10))
		assert.same({}, env.requests)
	end)
end)

describe("SentientSystems_UnitAction", function()
	local KNIGHT = { id = 6160397, type = "UNIT_KNIGHT", x = 10, y = 10, moves = 2 }

	it("fails for a unit the player doesn't have", function()
		assert.equal(Failed("Player 0 has no unit 5."), Load(KNIGHT).SentientSystems_UnitAction(0, 5, "fortify"))
	end)

	it("fails for an action it doesn't know, and lists the actions", function()
		assert.equal(Failed("Unknown unit action dance. The actions are activate, add_production, airlift, alert, attack, build_road, condemn_heretic, delete, deploy, enter_formation, evangelize_belief, exit_formation, form_army, form_corps, fortify, found_city, found_religion, harvest, harvest_wonder, heal, heal_followers, improve, launch_inquisition, paradrop, pillage, plunder, priority_target, promote, rebase, remove_feature, remove_heresy, remove_improvement, repair, skip, sleep, spread_religion, upgrade, wake."), Load(KNIGHT).SentientSystems_UnitAction(0, KNIGHT.id, "dance"))
	end)
end)
