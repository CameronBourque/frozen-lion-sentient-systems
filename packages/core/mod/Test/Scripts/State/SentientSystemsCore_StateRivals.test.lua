local FakeGame = require("FakeGame")
local Game = require("Game")
local Helpers = require("Helpers")

local With = Helpers.With

local RA_KEDET = {
	id = 65536, name = "LOC_CITY_NAME_RA_KEDET", x = 30, y = 18, population = 2, capital = true,
	defense = { strength = 12.6, garrison = { damage = 50, max = 200 } },
}

-- Returns the rival cities JSON in the state for player 0, with Egypt as player
-- 1.
local function RivalCitiesFor(me, egyptCities)
	local env = Game.new()

	FakeGame.Install(env, {
		players = { [0] = me, [1] = { cities = egyptCities } },
		text = { LOC_CITY_NAME_RA_KEDET = "Râ-Kedet" },
	})
	Game.run(env, "Scripts/State/SentientSystemsCore_State.lua")

	return env.SentientSystems_GetState(0):match("\"rivals\":{\"cities\":(%b[]),")
end

local WARRIOR = { id = 131073, type = "UNIT_WARRIOR", x = 25, y = 14, moves = 2, maxMoves = 2 }

-- Returns the rival units JSON in the state for player 0, with Egypt as player
-- 1.
local function RivalUnitsFor(me, egyptUnits)
	local env = Game.new()

	FakeGame.Install(env, { players = { [0] = me, [1] = { units = egyptUnits } } })
	Game.run(env, "Scripts/State/SentientSystemsCore_State.lua")

	return env.SentientSystems_GetState(0):match("\"rivals\":{\"cities\":%b[],\"units\":(%b[])")
end

describe("SentientSystems_GetRivalCityStates", function()
	it("lists a rival city on a revealed tile, with its owner and its banner's values", function()
		assert.equal(
			"[{\"capital\":true,\"defense\":{\"garrison\":{\"max\":200,\"value\":150},\"strength\":13},\"id\":65536,"
				.. "\"name\":\"Râ-Kedet\",\"owner\":1,\"population\":2,\"religion\":{\"outwardPressure\":0,\"present\":[]},\"x\":30,\"y\":18}]",
			RivalCitiesFor({ revealed = { { 30, 18 } } }, { RA_KEDET })
		)
	end)

	it("gives a rival city's religion, majority, and conversion, as its banner shows them", function()
		local city = {}

		for key, value in pairs(RA_KEDET) do
			city[key] = value
		end

		city.majority = "RELIGION_TAOISM"
		city.outwardPressure = 2
		city.religions = { { type = "RELIGION_TAOISM", followers = 4, pressure = 10, totalPressure = 300 }, { type = "RELIGION_SHINTO", followers = 1, pressure = 5, totalPressure = 90 } }
		city.converting = { type = "RELIGION_SHINTO", turns = 155 }

		assert.truthy(RivalCitiesFor({ revealed = { { 30, 18 } } }, { city }):find(
			"\"religion\":{\"converting\":{\"turns\":155,\"type\":\"RELIGION_SHINTO\"},\"majority\":\"RELIGION_TAOISM\",\"outwardPressure\":2,\"present\":["
				.. "{\"followers\":4,\"pressure\":10,\"totalPressure\":300,\"type\":\"RELIGION_TAOISM\"},"
				.. "{\"followers\":1,\"pressure\":5,\"totalPressure\":90,\"type\":\"RELIGION_SHINTO\"}]}",
			1,
			true
		))
	end)

	it("adds the walls' health when the city has walls", function()
		local city = {}

		for key, value in pairs(RA_KEDET) do
			city[key] = value
		end

		city.defense = { strength = 20, walls = { damage = 10, max = 100 } }

		assert.truthy(RivalCitiesFor({ visible = { { 30, 18 } } }, { city }):find("\"walls\":{\"max\":100,\"value\":90}", 1, true))
	end)

	it("leaves out a rival city on a tile the player hasn't revealed", function()
		assert.equal("[]", RivalCitiesFor({}, { RA_KEDET }))
	end)

	it("leaves out the player's own cities", function()
		local env = Game.new()

		FakeGame.Install(env, { players = { [0] = { cities = { RA_KEDET }, visible = { { 30, 18 } } } } })
		Game.run(env, "Scripts/State/SentientSystemsCore_State.lua")

		assert.truthy(env.SentientSystems_GetState(0):find("\"rivals\":{\"cities\":[],\"units\":[]}", 1, true))
	end)
end)

describe("SentientSystems_GetRivalUnitStates", function()
	it("lists a rival unit on a visible tile, with its owner, type, position, and health", function()
		assert.equal(
			"[{\"health\":{\"max\":100,\"value\":70},\"id\":131073,\"owner\":1,\"type\":\"UNIT_WARRIOR\",\"x\":25,\"y\":14}]",
			RivalUnitsFor({ visible = { { 25, 14 } } }, { With(WARRIOR, { damage = 30 }) })
		)
	end)

	it("gives the religion of a rival religious unit", function()
		local units = RivalUnitsFor({ visible = { { 25, 14 } } }, { With(WARRIOR, { religion = "RELIGION_SHINTO", religiousStrength = 100 }) })

		assert.truthy(units:find("\"religion\":\"RELIGION_SHINTO\"", 1, true))
		assert.truthy(units:find("\"religiousStrength\":100", 1, true))
	end)

	it("leaves out the religion of a rival unit with no religious strength", function()
		assert.is_nil(RivalUnitsFor({ visible = { { 25, 14 } } }, { With(WARRIOR, { religion = "RELIGION_SHINTO" }) }):find("eligio", 1, true))
	end)

	it("leaves out a rival unit on a fogged tile", function()
		assert.equal("[]", RivalUnitsFor({ revealed = { { 25, 14 } } }, { WARRIOR }))
	end)

	it("leaves out a rival unit that IsUnitVisible hides on a visible tile", function()
		assert.equal("[]", RivalUnitsFor({ visible = { { 25, 14 } } }, { With(WARRIOR, { hidden = true }) }))
	end)

	it("leaves out a rival unit that isn't on the map or is dead", function()
		assert.equal("[]", RivalUnitsFor({ visible = { { 25, 14 } } }, { With(WARRIOR, { x = -9999 }), With(WARRIOR, { dead = true }) }))
	end)

	it("leaves out the player's own units", function()
		local env = Game.new()

		FakeGame.Install(env, { players = { [0] = { units = { WARRIOR }, visible = { { 25, 14 } } } } })
		Game.run(env, "Scripts/State/SentientSystemsCore_State.lua")

		assert.truthy(env.SentientSystems_GetState(0):find("\"rivals\":{\"cities\":[],\"units\":[]}", 1, true))
	end)
end)
