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

describe("the stance, wake, delete, plunder, and promote actions", function()
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

	it("requests the plunder command for a unit the game lets plunder now", function()
		local env = Load(Allowing({ "plunder" }))

		assert.equal("{\"ok\":true}", env.SentientSystems_UnitAction(0, KNIGHT.id, "plunder"))
		assert.same({ { unit = KNIGHT.id, command = env.UnitCommandTypes.PLUNDER_TRADE_ROUTE } }, env.requests)
	end)

	it("fails to plunder for a unit with no strength, and explains the tile for one with", function()
		assert.equal(Failed("This kind of unit can't plunder."), Load(With(KNIGHT, { type = "UNIT_SCOUT" })).SentientSystems_UnitAction(0, KNIGHT.id, "plunder"))
		assert.equal(
			Failed("No trade route of a player at war with you is on the tile, or it is immune to plunder."),
			Load(KNIGHT).SentientSystems_UnitAction(0, KNIGHT.id, "plunder")
		)
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
