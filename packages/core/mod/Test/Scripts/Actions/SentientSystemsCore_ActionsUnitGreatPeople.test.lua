local FakeGame = require("FakeGame")
local Game = require("Game")

local ENGINEER = { id = 5898263, type = "UNIT_GREAT_ENGINEER", x = 10, y = 10, moves = 4, greatPerson = "GREAT_PERSON_CLASS_ENGINEER" }

-- Returns an environment with the actions loaded into a fake game that has
-- player 0 with the unit.
local function Load(unit)
	local env = Game.new()

	FakeGame.Install(env, { players = { [0] = { units = { unit } } } })
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

local ORDERS = {
	{ action = "activate", command = "UNITCOMMAND_ACTIVATE_GREAT_PERSON", verb = "activate a great person" },
	{ action = "harvest_wonder", command = "UNITCOMMAND_HARVEST_WONDER", verb = "harvest a wonder" },
}

for _, order in ipairs(ORDERS) do
	describe(order.action, function()
		it("requests the command the game allows", function()
			local env = Load(With(ENGINEER, { canNow = { order.action } }))

			assert.equal("{\"ok\":true}", env.SentientSystems_UnitAction(0, ENGINEER.id, order.action))
			assert.same({ { unit = ENGINEER.id, command = env.GameInfo.UnitCommands[order.command].Hash } }, env.requests)
		end)

		it("fails for a unit that isn't a great person", function()
			local env = Load(With(ENGINEER, { type = "UNIT_KNIGHT", greatPerson = false }))

			assert.equal(Failed("This kind of unit can't " .. order.verb .. "."), env.SentientSystems_UnitAction(0, ENGINEER.id, order.action))
		end)

		it("returns the reasons the game gives", function()
			local env = Load(With(ENGINEER, { reasons = { "LOC_NOT_OWNED", "LOC_NO_WONDER" } }))

			assert.equal(Failed("LOC_NOT_OWNED LOC_NO_WONDER"), env.SentientSystems_UnitAction(0, ENGINEER.id, order.action))
		end)

		it("says so when the game gives no reason", function()
			assert.equal(Failed("The unit can't " .. order.verb .. " now."), Load(ENGINEER).SentientSystems_UnitAction(0, ENGINEER.id, order.action))
		end)
	end)
end
