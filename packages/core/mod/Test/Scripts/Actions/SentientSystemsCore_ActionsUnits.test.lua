local FakeGame = require("FakeGame")
local Game = require("Game")

local SCOUT = { id = 196608, type = "UNIT_SCOUT", x = 10, y = 10, moves = 3, paths = { { x = 11, y = 10 }, { x = 40, y = 40 } } }

-- Returns an environment with the actions loaded into a fake game that has
-- player 0 with the unit, who sees the given tiles.
local function Load(unit, visible)
	local env = Game.new()

	FakeGame.Install(env, { players = { [0] = { units = { unit }, visible = visible } } })
	Game.run(env, "Scripts/Actions/SentientSystemsCore_Actions.lua")

	return env
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

local function Failed(reason)
	return "{\"ok\":false,\"reason\":\"" .. reason .. "\"}"
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

		assert.equal(Failed("Air units can't move with this action."), env.SentientSystems_MoveUnit(0, SCOUT.id, 11, 10))
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

	-- Returns the unit with the actions that the game's checks allow.
	local function Allowing(actions, changes)
		return With(With(KNIGHT, { canEver = actions, canNow = actions }), changes or {})
	end

	it("requests each stance operation the game allows", function()
		for _, action in ipairs({ "fortify", "sleep", "skip", "alert", "heal" }) do
			local env = Load(Allowing({ action }))
			local hash = env.GameInfo.UnitOperations["UNITOPERATION_" .. (action == "skip" and "SKIP_TURN" or action:upper())].Hash

			assert.equal("{\"ok\":true}", env.SentientSystems_UnitAction(0, KNIGHT.id, action))
			assert.same({ { unit = KNIGHT.id, operation = hash } }, env.requests)
		end
	end)

	it("requests the wake and delete commands the game allows", function()
		local wake = Load(Allowing({ "wake" }, { activity = "HOLD" }))
		local delete = Load(Allowing({ "delete" }))

		assert.equal("{\"ok\":true}", wake.SentientSystems_UnitAction(0, KNIGHT.id, "wake"))
		assert.same({ { unit = KNIGHT.id, command = wake.UnitCommandTypes.WAKE } }, wake.requests)
		assert.equal("{\"ok\":true}", delete.SentientSystems_UnitAction(0, KNIGHT.id, "delete"))
		assert.same({ { unit = KNIGHT.id, command = delete.UnitCommandTypes.DELETE } }, delete.requests)
	end)

	it("fails for a unit the player doesn't have", function()
		assert.equal(Failed("Player 0 has no unit 5."), Load(KNIGHT).SentientSystems_UnitAction(0, 5, "fortify"))
	end)

	it("fails for an action it doesn't know, and lists the actions", function()
		assert.equal(Failed("Unknown unit action dance. The actions are alert, delete, fortify, heal, promote, skip, sleep, wake."), Load(KNIGHT).SentientSystems_UnitAction(0, KNIGHT.id, "dance"))
	end)

	it("fails for a stance the unit could never take", function()
		local env = Load(KNIGHT)

		assert.equal(Failed("This kind of unit can't fortify."), env.SentientSystems_UnitAction(0, KNIGHT.id, "fortify"))
		assert.equal(Failed("This kind of unit can't delete."), env.SentientSystems_UnitAction(0, KNIGHT.id, "delete"))
		assert.same({}, env.requests)
	end)

	it("fails for a stance the unit can't take now", function()
		local env = Load(With(KNIGHT, { canEver = { "fortify" } }))

		assert.equal(Failed("The unit can't fortify now."), env.SentientSystems_UnitAction(0, KNIGHT.id, "fortify"))
		assert.same({}, env.requests)
	end)

	it("tells a unit that isn't awake to wake first, when the game would wake it", function()
		for activity, text in pairs({ SLEEP = "sleeping", HOLD = "skipping its turn", SENTRY = "fortified or on alert" }) do
			local env = Load(With(KNIGHT, { activity = activity, canEver = { "fortify", "wake" }, canNow = { "wake" } }))

			assert.equal(Failed("The unit is " .. text .. ". Wake it first."), env.SentientSystems_UnitAction(0, KNIGHT.id, "fortify"))
		end
	end)

	it("doesn't tell a unit to wake when the game won't wake it", function()
		local env = Load(With(KNIGHT, { activity = "OPERATION", canEver = { "fortify" } }))

		assert.equal(Failed("The unit is busy with an order."), env.SentientSystems_UnitAction(0, KNIGHT.id, "fortify"))
	end)

	it("lets a unit that isn't awake take the order that the game allows, such as alert", function()
		assert.equal("{\"ok\":true}", Load(Allowing({ "alert" }, { activity = "SENTRY" })).SentientSystems_UnitAction(0, KNIGHT.id, "alert"))
	end)

	it("fails to wake a unit that is awake, or that the game won't wake", function()
		assert.equal(Failed("The unit is already awake."), Load(With(KNIGHT, { canEver = { "wake" } })).SentientSystems_UnitAction(0, KNIGHT.id, "wake"))
		assert.equal(Failed("The unit can't wake now."), Load(With(KNIGHT, { activity = "SLEEP", canEver = { "wake" } })).SentientSystems_UnitAction(0, KNIGHT.id, "wake"))
	end)

	describe("promote", function()
		local CARAVEL = With(KNIGHT, { type = "UNIT_CARAVEL", experience = { points = 45, nextLevel = 45, promotions = {}, available = { "PROMOTION_HELMSMAN", "PROMOTION_REINFORCED_HULL" } } })

		it("requests the promotion by its index", function()
			local env = Load(CARAVEL)
			local index

			for i = 0, #env.GameInfo.UnitPromotions do
				if env.GameInfo.UnitPromotions[i].UnitPromotionType == "PROMOTION_REINFORCED_HULL" then
					index = env.GameInfo.UnitPromotions[i].Index
				end
			end

			assert.equal("{\"ok\":true}", env.SentientSystems_UnitAction(0, KNIGHT.id, "promote", nil, nil, "PROMOTION_REINFORCED_HULL"))
			assert.same({ { unit = KNIGHT.id, command = env.UnitCommandTypes.PROMOTE, parameters = { [env.UnitCommandTypes.PARAM_PROMOTION_TYPE] = index } } }, env.requests)
		end)

		it("fails for a promotion the unit can't take, and lists the ones it can", function()
			local env = Load(CARAVEL)

			assert.equal(Failed("The unit can't take PROMOTION_AMBUSH. It can take PROMOTION_HELMSMAN, PROMOTION_REINFORCED_HULL."), env.SentientSystems_UnitAction(0, KNIGHT.id, "promote", nil, nil, "PROMOTION_AMBUSH"))
			assert.equal(Failed("The unit can't take nil. It can take PROMOTION_HELMSMAN, PROMOTION_REINFORCED_HULL."), env.SentientSystems_UnitAction(0, KNIGHT.id, "promote"))
			assert.same({}, env.requests)
		end)

		it("fails for a unit with no promotion to pick", function()
			assert.equal(Failed("The unit has no promotion to pick."), Load(KNIGHT).SentientSystems_UnitAction(0, KNIGHT.id, "promote", nil, nil, "PROMOTION_AMBUSH"))
		end)
	end)
end)
