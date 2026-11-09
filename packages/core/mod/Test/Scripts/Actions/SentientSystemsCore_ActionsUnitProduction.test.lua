local FakeGame = require("FakeGame")
local Game = require("Game")
local Helpers = require("Helpers")

local Failed, With = Helpers.Failed, Helpers.With

local ENGINEER = { id = 7405612, type = "UNIT_MILITARY_ENGINEER", x = 20, y = 20, moves = 2, charges = 2 }
local FLOOD_BARRIER = { type = "BUILDING_FLOOD_BARRIER", turns = 3, cost = 40, progress = 0 }
local AQUEDUCT = { type = "DISTRICT_AQUEDUCT", plot = { x = 21, y = 20 } }

-- Runs the action for the unit in a fake game where player 0 has the unit and,
-- when producing is given, a city on the unit's tile producing it.
local function Run(unit, producing)
	local env = Game.new()
	local player = { units = { unit } }

	if producing ~= nil then
		local city = {
			id = 65536,
			name = "Rome",
			x = 20,
			y = 20,
			population = 3,
			ownedTiles = { { x = 21, y = 20 } },
			options = { buildings = { FLOOD_BARRIER }, districts = { { type = "DISTRICT_AQUEDUCT", turns = 3 } } },
		}

		if producing ~= "nothing" then
			city.production = producing
		end

		player.cities = { city }
	end

	FakeGame.Install(env, { players = { [0] = player } })
	Game.run(env, "Scripts/Actions/SentientSystemsCore_Actions.lua")

	-- The fake rows have no names, so give each type a text key.
	for _, row in pairs(env.GameInfo.Buildings) do
		row.Name = "LOC_" .. row.BuildingType
	end

	for _, row in pairs(env.GameInfo.Districts) do
		row.Name = "LOC_" .. row.DistrictType
	end

	return env.SentientSystems_UnitAction(0, unit.id, "add_production"), env
end

describe("add_production", function()
	local READY = With(ENGINEER, { canNow = { "building_production" } })

	it("requests the command the game allows, with no parameters", function()
		local result, env = Run(READY, FLOOD_BARRIER)

		assert.equal("{\"ok\":true}", result)
		assert.same({ { unit = ENGINEER.id, command = env.GameInfo.UnitCommands["UNITCOMMAND_BUILDING_PRODUCTION"].Hash } }, env.requests)
	end)

	it("tries the district, wonder, and project commands too", function()
		for _, name in ipairs({ "district_production", "wonder_production", "project_production" }) do
			local result, env = Run(With(ENGINEER, { canNow = { name } }), FLOOD_BARRIER)

			assert.equal("{\"ok\":true}", result)
			assert.equal(env.GameInfo.UnitCommands["UNITCOMMAND_" .. name:upper()].Hash, env.requests[1].command)
		end
	end)

	it("fails for a unit that is not a builder", function()
		local knight = { id = ENGINEER.id, type = "UNIT_KNIGHT", x = 20, y = 20, moves = 4 }

		assert.equal(Failed("This kind of unit can't add production."), (Run(knight, FLOOD_BARRIER)))
	end)

	it("says the unit has no moves left", function()
		assert.equal(Failed("The unit has no moves left."), (Run(With(ENGINEER, { moves = 0 }), FLOOD_BARRIER)))
	end)

	it("says the unit has to be in a city or on the tile of a district", function()
		assert.equal(Failed("The unit has to be in a city, or on the tile of a district or wonder that a city is building."), (Run(ENGINEER)))
	end)

	it("says where a district is being built when the unit is in the city", function()
		local reason = "Rome is building LOC_DISTRICT_AQUEDUCT on the tile (21, 20). A unit that can add to it has to stand there."

		assert.equal(Failed(reason), (Run(ENGINEER, AQUEDUCT)))
	end)

	it("fails on the tile of the district for a unit that can't add to it", function()
		local builder = With(ENGINEER, { type = "UNIT_BUILDER", x = 21, y = 20 })

		assert.equal(Failed("Rome is building LOC_DISTRICT_AQUEDUCT, and this unit can't add production to it."), (Run(builder, AQUEDUCT)))
	end)

	it("names what the city is building", function()
		assert.equal(Failed("Rome is building LOC_BUILDING_FLOOD_BARRIER, and this unit can't add production to it."), (Run(ENGINEER, FLOOD_BARRIER)))
	end)

	it("says the city is building nothing", function()
		assert.equal(Failed("Rome is not building anything."), (Run(ENGINEER, "nothing")))
	end)
end)
