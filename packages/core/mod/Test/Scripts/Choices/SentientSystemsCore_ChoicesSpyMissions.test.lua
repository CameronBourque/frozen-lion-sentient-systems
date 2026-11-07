local FakeGame = require("FakeGame")
local Game = require("Game")

-- Cities of player 0 and of player 1, a rival, and of player 5, a city-state,
-- with the districts and the plots each mission targets.
local HOME = {
	id = 1,
	name = "LOC_CITY_HOME",
	x = 10,
	y = 10,
	population = 5,
	districts = { { type = "DISTRICT_CITY_CENTER", x = 10, y = 10 }, { type = "DISTRICT_CAMPUS", x = 11, y = 10 } },
}
local RIVAL = {
	id = 1,
	name = "LOC_CITY_RIVAL",
	x = 30,
	y = 10,
	population = 5,
	capital = true,
	districts = {
		{ type = "DISTRICT_CITY_CENTER", x = 30, y = 10 },
		{ type = "DISTRICT_COMMERCIAL_HUB", x = 31, y = 10 },
		{ type = "DISTRICT_THEATER", x = 32, y = 10, complete = false },
		{ type = "DISTRICT_WONDER", x = 33, y = 10 },
	},
}
local STATE = { id = 1, name = "LOC_CITY_STATE", x = 50, y = 10, population = 5, districts = { { type = "DISTRICT_CITY_CENTER", x = 50, y = 10 } } }
local MINOR = { name = "STATE", leader = "LEADER_MINOR_CIV_STATE" }

local PLOTS = {
	{ x = 10, y = 10, terrain = "TERRAIN_GRASS", district = "DISTRICT_CITY_CENTER" },
	{ x = 11, y = 10, terrain = "TERRAIN_GRASS", district = "DISTRICT_CAMPUS" },
	{ x = 30, y = 10, terrain = "TERRAIN_GRASS", district = "DISTRICT_CITY_CENTER" },
	{ x = 31, y = 10, terrain = "TERRAIN_GRASS", district = "DISTRICT_COMMERCIAL_HUB" },
}

local OPS = {
	UNITOPERATION_SPY_TRAVEL_NEW_CITY = {},
	UNITOPERATION_SPY_COUNTERSPY = { plots = { { x = 10, y = 10 }, { x = 11, y = 10 } } },
	UNITOPERATION_SPY_GAIN_SOURCES = { turns = 4, detail = "[ICON_Bullet]Two levels higher", chances = { ESPIONAGE_SUCCESS_UNDETECTED = 1 } },
	UNITOPERATION_SPY_LISTENING_POST = { turns = 4, chances = { ESPIONAGE_SUCCESS_UNDETECTED = 1 } },
	UNITOPERATION_SPY_SIPHON_FUNDS = {
		plots = { { x = 31, y = 10 } },
		turns = 4,
		detail = "+92",
		chances = {
			ESPIONAGE_SUCCESS_UNDETECTED = 0.26,
			ESPIONAGE_SUCCESS_MUST_ESCAPE = 0.24,
			ESPIONAGE_FAIL_UNDETECTED = 0.125,
			ESPIONAGE_FAIL_MUST_ESCAPE = 0.21,
		},
	},
	UNITOPERATION_SPY_FOMENT_UNREST = { turns = 5, detail = "-20", chances = { ESPIONAGE_SUCCESS_UNDETECTED = 0.5, ESPIONAGE_FAIL_UNDETECTED = 0.5 } },
	UNITOPERATION_SPY_GREAT_WORK_HEIST = { reasons = { "LOC_NO_GREAT_WORK" }, turns = 3 },
}

local TRAVEL = { { player = 0, id = 1, travel = 1, establish = 0 }, { player = 1, id = 1, travel = 2, establish = 1 }, { player = 5, id = 1, travel = 3, establish = 1 } }

local function With(base, changes)
	local copy = {}

	for key, value in pairs(base) do
		copy[key] = value
	end

	for key, value in pairs(changes) do
		copy[key] = value
	end

	return copy
end

-- A spy of player 0 standing at x, y.
local function Spy(x, y, changes)
	return With({ id = 700, type = "UNIT_SPY", x = x, y = y, name = "LOC_CITIZEN_SPY", spy = { travel = TRAVEL, ops = OPS } }, changes or {})
end

-- Returns the spy missions choice JSON for player 0, or nil when it is left
-- out, with the units given and the players that replace the defaults. It
-- calls the choice alone, as the other choices ask the game about each
-- district a city has.
local function ChoicesWith(units, players)
	local env = Game.new()
	local world = {
		players = {
			[0] = { units = units, cities = { HOME }, revealed = { { 10, 10 }, { 30, 10 }, { 50, 10 } } },
			[1] = { cities = { RIVAL } },
			[5] = { minor = MINOR, cities = { STATE } },
		},
		plots = PLOTS,
		text = { LOC_CITIZEN_SPY = "Chloe" },
	}

	for id, data in pairs(players or {}) do
		world.players[id] = data
	end

	FakeGame.Install(env, world)
	Game.run(env, "Scripts/Choices/SentientSystemsCore_Choices.lua")

	local choices = env.SentientSystems_GetSpyMissionChoices(env.Players[0])

	return choices and env.SentientSystems_EncodeJson(choices)
end

describe("SentientSystems_GetSpyMissionChoices", function()
	it("is left out with no spy", function()
		assert.is_nil(ChoicesWith({ { id = 5, type = "UNIT_KNIGHT", x = 10, y = 10 } }))
	end)

	it("lists the counterspy missions of a spy in a city of the player's", function()
		local json = ChoicesWith({ Spy(10, 10) })

		assert.truthy(json:find("\"city\":{\"id\":1,\"name\":\"LOC_CITY_HOME\",\"owner\":0}", 1, true))
		assert.truthy(json:find("\"missions\":[{\"details\":\"LOC_ESPIONAGECHOOSER_COUNTERSPY(LOC_DISTRICT_CITY_CENTER_NAME)\",\"district\":\"DISTRICT_CITY_CENTER\"", 1, true))
		assert.truthy(json:find("\"district\":\"DISTRICT_CAMPUS\"", 1, true))
		assert.truthy(json:find("\"name\":\"Chloe\"", 1, true))
	end)

	it("lists the cities a spy can travel to with turns and districts, wonders and unfinished districts left out", function()
		local json = ChoicesWith({ Spy(10, 10) })

		assert.truthy(json:find("\"destinations\":[{\"districts\":[\"DISTRICT_CITY_CENTER\",\"DISTRICT_CAMPUS\"],\"establish\":0,\"id\":1,\"name\":\"LOC_CITY_HOME\",\"owner\":0,\"travel\":1,\"turns\":1}", 1, true))
		assert.truthy(json:find("{\"capital\":true,\"districts\":[\"DISTRICT_CITY_CENTER\",\"DISTRICT_COMMERCIAL_HUB\"],\"establish\":1,\"id\":1,\"name\":\"LOC_CITY_RIVAL\",\"owner\":1,\"travel\":2,\"turns\":3}", 1, true))
		assert.truthy(json:find("\"name\":\"LOC_CITY_STATE\",\"owner\":5,\"travel\":3,\"turns\":4}", 1, true))
	end)

	it("leaves out an ally, a teammate, and the Free Cities", function()
		local ally = ChoicesWith({ Spy(10, 10) }, { [1] = { cities = { RIVAL }, diplomacy = { [0] = { state = "DIPLO_STATE_ALLIED" } } } })
		local team = ChoicesWith({ Spy(10, 10) }, { [5] = { minor = MINOR, cities = { STATE }, team = 0 } })
		local free = ChoicesWith({ Spy(10, 10) }, { [5] = { minor = MINOR, cities = { STATE }, freeCities = true } })

		assert.is_nil(ally:find("LOC_CITY_RIVAL", 1, true))
		assert.is_nil(team:find("LOC_CITY_STATE", 1, true))
		assert.is_nil(free:find("LOC_CITY_STATE", 1, true))
	end)

	it("lists the offensive missions in a rival's city with their target, time, details, and chances", function()
		local json = ChoicesWith({ Spy(30, 10) })

		assert.truthy(json:find("\"city\":{\"id\":1,\"name\":\"LOC_CITY_RIVAL\",\"owner\":1}", 1, true))
		assert.truthy(json:find("\"chances\":{\"success\":100},\"details\":\"LOC_SPYMISSIONDETAILS_UNITOPERATION_SPY_LISTENING_POST\",\"district\":\"DISTRICT_CITY_CENTER\",\"districtName\":\"LOC_DISTRICT_CITY_CENTER_NAME\"", 1, true))
		assert.truthy(json:find("\"chances\":{\"captured\":16,\"failure\":34,\"success\":50}", 1, true))
		assert.truthy(json:find("\"details\":\"LOC_SPYMISSIONDETAILS_UNITOPERATION_SPY_SIPHON_FUNDS(LOC_CITY_RIVAL,+92)\",\"district\":\"DISTRICT_COMMERCIAL_HUB\"", 1, true))
		assert.truthy(json:find("\"details\":\"LOC_SPYMISSIONDETAILS_UNITOPERATION_SPY_FOMENT_UNREST(-20)\"", 1, true))
		assert.truthy(json:find("\"details\":\"-Two levels higher\"", 1, true))
	end)

	it("warns that a rival will learn of a mission that can fail, and not a city-state", function()
		local rival = ChoicesWith({ Spy(30, 10) })
		local state = ChoicesWith({ Spy(50, 10) })

		assert.truthy(rival:find("\"warning\":\"LOC_ESPIONAGEPOPUP_DISCOVERED_WARNING(", 1, true))
		assert.is_nil(state:find("\"warning\"", 1, true))
	end)

	it("lists a mission the game refuses with its reasons", function()
		assert.truthy(ChoicesWith({ Spy(30, 10) }):find("\"disabled\":[\"LOC_NO_GREAT_WORK\"]", 1, true))
	end)

	it("leaves out a spy on a mission or asleep, and the trips for a spy the game won't send", function()
		assert.is_nil(ChoicesWith({ Spy(30, 10, { spy = { ready = false, ops = OPS } }) }))
		assert.is_nil(ChoicesWith({ Spy(30, 10, { activity = "SLEEP" }) }))

		local ops = With(OPS, {})

		ops.UNITOPERATION_SPY_TRAVEL_NEW_CITY = nil

		assert.is_nil(ChoicesWith({ Spy(30, 10, { spy = { ops = ops, travel = TRAVEL } }) }):find("\"destinations\"", 1, true))
	end)

	it("lists a spy in no city with its trips only", function()
		local json = ChoicesWith({ Spy(20, 20) })

		assert.is_nil(json:find("\"city\"", 1, true))
		assert.is_nil(json:find("\"missions\"", 1, true))
		assert.truthy(json:find("\"destinations\"", 1, true))
	end)
end)
