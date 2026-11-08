local FakeGame = require("FakeGame")
local Game = require("Game")
local Helpers = require("Helpers")

local Failed, With = Helpers.Failed, Helpers.With

local PROPHET = { id = 3801115, type = "UNIT_GREAT_PROPHET", x = 20, y = 20, moves = 4 }
local MISSIONARY = { id = 3801116, type = "UNIT_MISSIONARY", x = 20, y = 20, moves = 3 }
local INQUISITOR = { id = 3801119, type = "UNIT_INQUISITOR", x = 20, y = 20, moves = 3 }
local GURU = { id = 3801117, type = "UNIT_GURU", x = 20, y = 20, moves = 3 }

-- Returns an environment with the actions loaded into a fake game that has
-- player 0 with the unit.
local function Load(unit)
	local env = Game.new()

	FakeGame.Install(env, { players = { [0] = { units = { unit } } } })
	Game.run(env, "Scripts/Actions/SentientSystemsCore_Actions.lua")

	return env
end

local ORDERS = {
	{ action = "found_religion", unit = PROPHET, operation = "UNITOPERATION_FOUND_RELIGION", verb = "found a religion", other = MISSIONARY, need = "The unit can't found a religion now." },
	{ action = "spread_religion", unit = MISSIONARY, operation = "UNITOPERATION_SPREAD_RELIGION", verb = "spread a religion", other = PROPHET, need = "It spreads from a city, and needs a religion and a charge left." },
	{ action = "remove_heresy", unit = INQUISITOR, operation = "UNITOPERATION_REMOVE_HERESY", verb = "remove a heresy", other = MISSIONARY, need = "It removes other religions from a city that follows your religion, and needs a charge left." },
	{ action = "heal_followers", unit = GURU, operation = "UNITOPERATION_RELIGIOUS_HEAL", verb = "heal followers", other = MISSIONARY, need = "It needs a wounded religious unit on its tile or next to it, itself included." },
}

for _, order in ipairs(ORDERS) do
	describe(order.action, function()
		it("requests the operation the game allows", function()
			local env = Load(With(order.unit, { canNow = { order.action } }))

			assert.equal("{\"ok\":true}", env.SentientSystems_UnitAction(0, order.unit.id, order.action))
			assert.same({ { unit = order.unit.id, operation = env.GameInfo.UnitOperations[order.operation].Hash } }, env.requests)
		end)

		it("fails for a kind of unit that can't do it", function()
			local env = Load(With(order.other, { id = order.unit.id }))

			assert.equal(Failed("This kind of unit can't " .. order.verb .. "."), env.SentientSystems_UnitAction(0, order.unit.id, order.action))
		end)

		it("returns the reasons the game gives, or says so when it gives none", function()
			local env = Load(With(order.unit, { reasons = { "LOC_NOT_HOLY_SITE" } }))

			assert.equal(Failed("LOC_NOT_HOLY_SITE"), env.SentientSystems_UnitAction(0, order.unit.id, order.action))
			assert.equal(Failed(order.need), Load(order.unit).SentientSystems_UnitAction(0, order.unit.id, order.action))
		end)
	end)
end

describe("condemn_heretic", function()
	local APOSTLE = { id = 3801118, type = "UNIT_APOSTLE", x = 20, y = 20, moves = 3 }

	it("requests the command the game allows", function()
		local env = Load(With(APOSTLE, { canNow = { "condemn_heretic" } }))

		assert.equal("{\"ok\":true}", env.SentientSystems_UnitAction(0, APOSTLE.id, "condemn_heretic"))
		assert.same({ { unit = APOSTLE.id, command = env.UnitCommandTypes.CONDEMN_HERETIC } }, env.requests)
	end)

	it("returns the game's reasons, or what the tile needs", function()
		local env = Load(With(APOSTLE, { reasons = { "LOC_NO_HERETIC" } }))

		assert.equal(Failed("LOC_NO_HERETIC"), env.SentientSystems_UnitAction(0, APOSTLE.id, "condemn_heretic"))
		assert.equal(
			Failed("It needs a religious unit of another religion, owned by a player at war with you, on its tile."),
			Load(APOSTLE).SentientSystems_UnitAction(0, APOSTLE.id, "condemn_heretic")
		)
	end)
end)
