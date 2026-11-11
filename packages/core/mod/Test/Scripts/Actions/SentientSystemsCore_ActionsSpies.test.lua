local FakeGame = require("FakeGame")
local Game = require("Game")
local Helpers = require("Helpers")

local Failed, With = Helpers.Failed, Helpers.With

local HOME = {
	id = 1,
	name = "LOC_CITY_HOME",
	x = 10,
	y = 10,
	population = 5,
	districts = { { type = "DISTRICT_CITY_CENTER", x = 10, y = 10 }, { type = "DISTRICT_CAMPUS", x = 11, y = 10 } },
}
local RIVAL = { id = 1, name = "LOC_CITY_RIVAL", x = 30, y = 10, population = 5, districts = { { type = "DISTRICT_CITY_CENTER", x = 30, y = 10 } } }
local STATE = { id = 1, name = "LOC_CITY_STATE", x = 50, y = 10, population = 5, districts = { { type = "DISTRICT_CITY_CENTER", x = 50, y = 10 } } }
local MINOR = { name = "STATE", leader = "LEADER_MINOR_CIV_STATE" }

local PLOTS = {
	{ x = 10, y = 10, terrain = "TERRAIN_GRASS", district = "DISTRICT_CITY_CENTER" },
	{ x = 11, y = 10, terrain = "TERRAIN_GRASS", district = "DISTRICT_CAMPUS" },
	{ x = 30, y = 10, terrain = "TERRAIN_GRASS", district = "DISTRICT_CITY_CENTER" },
}

local OPS = {
	UNITOPERATION_SPY_TRAVEL_NEW_CITY = { blocked = { { x = 50, y = 10 } } },
	UNITOPERATION_SPY_COUNTERSPY = { plots = { { x = 10, y = 10 }, { x = 11, y = 10 } } },
	UNITOPERATION_SPY_LISTENING_POST = { turns = 4, chances = { ESPIONAGE_SUCCESS_UNDETECTED = 1 } },
	UNITOPERATION_SPY_GREAT_WORK_HEIST = { reasons = { "LOC_NO_GREAT_WORK" } },
}

local TRAVEL = { { player = 0, id = 1, travel = 1, establish = 0 }, { player = 1, id = 1, travel = 2, establish = 1 }, { player = 5, id = 1, travel = 3, establish = 1 } }

-- A spy of player 0 standing at x, y.
local function Spy(x, y, changes)
	return With({ id = 700, type = "UNIT_SPY", x = x, y = y, spy = { travel = TRAVEL, ops = OPS } }, changes or {})
end

-- Returns an environment with the actions loaded into a fake game that has
-- player 0 with the unit, and a rival and a city-state of their own.
local function Load(unit, players)
	local env = Game.new()
	local world = {
		players = {
			[0] = { units = { unit }, cities = { HOME }, revealed = { { 10, 10 }, { 30, 10 }, { 50, 10 } } },
			[1] = { cities = { RIVAL } },
			[5] = { minor = MINOR, cities = { STATE } },
		},
		plots = PLOTS,
	}

	for id, data in pairs(players or {}) do
		world.players[id] = data
	end

	FakeGame.Install(env, world)
	Game.run(env, "Scripts/Actions/SentientSystemsCore_Actions.lua")

	return env
end

describe("SentientSystems_SpyMission", function()
	it("requests an offensive mission in the city the spy stands in, with no target as the briefing does", function()
		local env = Load(Spy(30, 10))

		assert.equal("{\"ok\":true}", env.SentientSystems_SpyMission(0, 700, "UNITOPERATION_SPY_LISTENING_POST"))
		assert.same({ { unit = 700, operation = env.GameInfo.UnitOperations["UNITOPERATION_SPY_LISTENING_POST"].Hash } }, env.requests)
	end)

	it("requests a counterspy mission for a district of the city, by its tile", function()
		local env = Load(Spy(10, 10))
		local types = env.UnitOperationTypes

		assert.equal("{\"ok\":true}", env.SentientSystems_SpyMission(0, 700, "UNITOPERATION_SPY_COUNTERSPY", "DISTRICT_CAMPUS"))
		assert.same({ { unit = 700, operation = types.SPY_COUNTERSPY, parameters = { [types.PARAM_X] = 11, [types.PARAM_Y] = 10 } } }, env.requests)
	end)

	it("fails for a unit that doesn't exist or isn't a spy", function()
		assert.equal(Failed("Player 0 has no unit 5."), Load(Spy(30, 10)).SentientSystems_SpyMission(0, 5, "UNITOPERATION_SPY_LISTENING_POST"))
		assert.equal(Failed("This kind of unit isn't a spy."), Load({ id = 700, type = "UNIT_KNIGHT", x = 30, y = 10 }).SentientSystems_SpyMission(0, 700, "UNITOPERATION_SPY_LISTENING_POST"))
	end)

	it("fails for a spy on a mission or on its way, and for one that is asleep", function()
		local busy = Load(Spy(30, 10, { spy = { ready = false, ops = OPS } }))

		assert.equal(Failed("The spy is on a mission or on its way."), busy.SentientSystems_SpyMission(0, 700, "UNITOPERATION_SPY_LISTENING_POST"))
		assert.equal(Failed("The unit is sleeping."), Load(Spy(30, 10, { activity = "SLEEP" })).SentientSystems_SpyMission(0, 700, "UNITOPERATION_SPY_LISTENING_POST"))
	end)

	it("fails for a spy in no city", function()
		assert.equal(Failed("The spy isn't in a city. Send it to one first."), Load(Spy(20, 20)).SentientSystems_SpyMission(0, 700, "UNITOPERATION_SPY_LISTENING_POST"))
	end)

	it("names the missions the spy can start when the mission isn't one of them", function()
		local env = Load(Spy(30, 10))

		assert.equal(
			Failed("The spy can't start UNITOPERATION_SPY_SIPHON_FUNDS here. It can start UNITOPERATION_SPY_LISTENING_POST, UNITOPERATION_SPY_GREAT_WORK_HEIST."),
			env.SentientSystems_SpyMission(0, 700, "UNITOPERATION_SPY_SIPHON_FUNDS")
		)
		assert.equal(
			Failed("UNITOPERATION_MOVE_TO isn't a spy mission. The spy can start UNITOPERATION_SPY_LISTENING_POST, UNITOPERATION_SPY_GREAT_WORK_HEIST."),
			env.SentientSystems_SpyMission(0, 700, "UNITOPERATION_MOVE_TO")
		)
		assert.equal(
			Failed("nil isn't a spy mission. The spy can start UNITOPERATION_SPY_LISTENING_POST, UNITOPERATION_SPY_GREAT_WORK_HEIST."),
			env.SentientSystems_SpyMission(0, 700, nil)
		)
	end)

	it("returns the game's reasons for a mission it refuses", function()
		assert.equal(Failed("LOC_NO_GREAT_WORK"), Load(Spy(30, 10)).SentientSystems_SpyMission(0, 700, "UNITOPERATION_SPY_GREAT_WORK_HEIST"))
	end)

	it("needs a district for a counterspy mission, and names the districts when it isn't one of them", function()
		local env = Load(Spy(10, 10))

		assert.equal(
			Failed("A counterspy mission needs the district to guard. The districts are DISTRICT_CITY_CENTER, DISTRICT_CAMPUS."),
			env.SentientSystems_SpyMission(0, 700, "UNITOPERATION_SPY_COUNTERSPY")
		)
		assert.equal(
			Failed("The spy can't guard DISTRICT_HARBOR. The districts are DISTRICT_CITY_CENTER, DISTRICT_CAMPUS."),
			env.SentientSystems_SpyMission(0, 700, "UNITOPERATION_SPY_COUNTERSPY", "DISTRICT_HARBOR")
		)
	end)
end)

describe("SentientSystems_SpyTravel", function()
	it("requests a trip to a destination by its tile", function()
		local env = Load(Spy(10, 10))
		local types = env.UnitOperationTypes

		assert.equal("{\"ok\":true}", env.SentientSystems_SpyTravel(0, 700, 1, 1))
		assert.same({ { unit = 700, operation = types.SPY_TRAVEL_NEW_CITY, parameters = { [types.PARAM_X] = 30, [types.PARAM_Y] = 10 } } }, env.requests)
	end)

	it("fails for a spy that can't act, and for a city that doesn't exist", function()
		assert.equal(Failed("The spy is on a mission or on its way."), Load(Spy(10, 10, { spy = { ready = false, ops = OPS } })).SentientSystems_SpyTravel(0, 700, 1, 1))

		local env = Load(Spy(10, 10))

		assert.equal(Failed("Player 1 has no city 9."), env.SentientSystems_SpyTravel(0, 700, 1, 9))
		assert.equal(Failed("Player 7 has no city 1."), env.SentientSystems_SpyTravel(0, 700, 7, 1))
		assert.equal(Failed("Player nil has no city nil."), env.SentientSystems_SpyTravel(0, 700, nil, nil))
	end)

	it("fails when the game won't send the spy anywhere", function()
		local ops = With(OPS, {})

		ops.UNITOPERATION_SPY_TRAVEL_NEW_CITY = nil

		assert.equal(Failed("The game won't send the spy to another city now."), Load(Spy(10, 10, { spy = { ops = ops, travel = TRAVEL } })).SentientSystems_SpyTravel(0, 700, 1, 1))
	end)

	it("fails for the city the spy is in", function()
		assert.equal(Failed("The spy is already in LOC_CITY_HOME."), Load(Spy(10, 10)).SentientSystems_SpyTravel(0, 700, 0, 1))
	end)

	it("fails for a city that isn't a destination, pointing at the choice", function()
		local env = Load(Spy(10, 10), { [5] = { minor = MINOR, cities = { STATE }, team = 0 } })

		assert.equal(
			Failed("LOC_CITY_STATE isn't a destination of this spy. Pick a city from its destinations in the spy missions choice."),
			env.SentientSystems_SpyTravel(0, 700, 5, 1)
		)
	end)

	it("fails for a destination that the game refuses once the request names it", function()
		assert.equal(Failed("The game won't send the spy to LOC_CITY_STATE."), Load(Spy(10, 10)).SentientSystems_SpyTravel(0, 700, 5, 1))
	end)
end)

describe("SentientSystems_ChooseEscapeRoute", function()
	local ESCAPING = { id = 2555922, name = "LOC_CITIZEN_ROME_FEMALE_3", loot = "LOC_ESPIONAGE_LOOT_NONE", pursuer = "", x = 84, y = 34 }
	local ISTANBUL = { id = 65536, name = "LOC_CITY_NAME_ISTANBUL", x = 84, y = 34, population = 5, districts = { { type = "DISTRICT_HARBOR", x = 85, y = 34 } } }
	local NO_SPY = "You have no spy escaping. The spies choice lists one when a spy is caught."

	-- Returns an environment where player 0's spy escapes from Istanbul, which
	-- has a harbor, with the blockers given, the escape route blocker when
	-- missing.
	local function LoadEscape(spy, blockers)
		return Load(nil, {
			[0] = { escapingSpy = spy, blockers = blockers or { "ENDTURN_BLOCKING_SPY_CHOOSE_ESCAPE_ROUTE" } },
			[4] = { cities = { ISTANBUL } },
		})
	end

	-- Returns the request the escape screen sends for the district.
	local function Request(env, district)
		local P = env.PlayerOperations

		return { { player = 0, operation = P.SET_ESCAPE_ROUTE, parameters = { [P.PARAM_DISTRICT_TYPE] = env.GameInfo.Districts[district].Index } } }
	end

	it("sends the escape screen's request for an open route", function()
		for _, district in ipairs({ "DISTRICT_HARBOR", "DISTRICT_CITY_CENTER" }) do
			local env = LoadEscape(ESCAPING)

			assert.equal("{\"ok\":true}", env.SentientSystems_ChooseEscapeRoute(0, district))
			assert.same(Request(env, district), env.requests)
		end
	end)

	it("sends the request for a dragnet priority too, which opens the same screen", function()
		local env = LoadEscape(ESCAPING, { "ENDTURN_BLOCKING_SPY_CHOOSE_DRAGNET_PRIORITY" })

		assert.equal("{\"ok\":true}", env.SentientSystems_ChooseEscapeRoute(0, "DISTRICT_HARBOR"))
		assert.same(Request(env, "DISTRICT_HARBOR"), env.requests)
	end)

	it("fails for a route the city has no district for, with the screen's reason", function()
		local env = LoadEscape(ESCAPING)

		assert.equal(Failed("LOC_ESPIONAGE_ESCAPE_NO_DISTRICT(LOC_DISTRICT_AERODROME_NAME)"), env.SentientSystems_ChooseEscapeRoute(0, "DISTRICT_AERODROME"))
		assert.same({}, env.requests)
	end)

	it("fails for a district that isn't a route", function()
		local env = LoadEscape(ESCAPING)

		assert.equal(
			Failed("DISTRICT_CAMPUS isn't an escape route. Use one of DISTRICT_HARBOR, DISTRICT_CITY_CENTER."),
			env.SentientSystems_ChooseEscapeRoute(0, "DISTRICT_CAMPUS")
		)
		assert.same({}, env.requests)
	end)

	it("fails with no spy escaping, or without a spy blocker", function()
		assert.equal(Failed(NO_SPY), LoadEscape(nil).SentientSystems_ChooseEscapeRoute(0, "DISTRICT_HARBOR"))
		assert.equal(Failed(NO_SPY), LoadEscape(ESCAPING, {}).SentientSystems_ChooseEscapeRoute(0, "DISTRICT_HARBOR"))
	end)

	it("fails for an ID with no player", function()
		assert.equal(Failed("ChooseEscapeRoute failed: no player 3"), LoadEscape(ESCAPING).SentientSystems_ChooseEscapeRoute(3, "DISTRICT_HARBOR"))
	end)
end)
