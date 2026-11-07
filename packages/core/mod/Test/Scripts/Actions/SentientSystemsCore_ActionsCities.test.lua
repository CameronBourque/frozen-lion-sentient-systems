local FakeGame = require("FakeGame")
local Game = require("Game")

-- A city at (20, 20) with a target on one tile in range and none on another.
local CITY = {
	id = 65536,
	name = "LOC_CITY_NAME_BIBRAX",
	x = 20,
	y = 20,
	attackTargets = { { x = 22, y = 20, target = true }, { x = 21, y = 20, target = false } },
}

-- Returns an environment with the actions loaded into a fake game that has
-- player 0 with the city, who sees the given tiles.
local function Load(city, visible)
	local env = Game.new()

	FakeGame.Install(env, { players = { [0] = { cities = { city }, visible = visible or { { 21, 20 }, { 22, 20 } } } } })
	Game.run(env, "Scripts/Actions/SentientSystemsCore_Actions.lua")

	return env
end

local function With(city, changes)
	local copy = {}

	for key, value in pairs(city) do
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

describe("SentientSystems_CityAttack", function()
	it("orders the shot at a target in range", function()
		local env = Load(CITY)

		assert.equal("{\"ok\":true}", env.SentientSystems_CityAttack(0, CITY.id, 22, 20))
		assert.same({ { city = CITY.id, command = env.CityCommandTypes.RANGE_ATTACK, parameters = { [env.UnitOperationTypes.PARAM_X] = 22, [env.UnitOperationTypes.PARAM_Y] = 20 } } }, env.requests)
	end)

	it("fails for a city the player doesn't have", function()
		local env = Load(CITY)

		assert.equal(Failed("Player 0 has no city 9."), env.SentientSystems_CityAttack(0, 9, 22, 20))
		assert.equal(Failed("Player 3 has no city 9."), env.SentientSystems_CityAttack(3, 9, 22, 20))
	end)

	it("fails for a tile off the map, or one the player can't see", function()
		local env = Load(CITY)

		assert.equal(Failed("That tile is off the map."), env.SentientSystems_CityAttack(0, CITY.id, -1, 4))
		assert.equal(Failed("That tile is off the map."), env.SentientSystems_CityAttack(0, CITY.id))
		assert.equal(Failed("You can't see that tile."), env.SentientSystems_CityAttack(0, CITY.id, 25, 20))
	end)

	it("fails for a tile that isn't a target, and lists the targets", function()
		local env = Load(CITY)

		assert.equal(Failed("That tile isn't a target. The targets in range are (22, 20)."), env.SentientSystems_CityAttack(0, CITY.id, 21, 20))
		assert.same({}, env.requests)
	end)

	it("fails when the game won't start the attack", function()
		assert.equal(Failed("The game won't start that attack."), Load(With(CITY, { attackBlocked = true })).SentientSystems_CityAttack(0, CITY.id, 22, 20))
	end)
end)

-- A city with production options: a unit, a building, a wonder, a district, a
-- project, a unit the city can't produce yet, and one the panel hides.
local PRODUCER = {
	id = 65536,
	name = "LOC_CITY_NAME_BIBRAX",
	x = 20,
	y = 20,
	options = {
		units = {
			{ type = "UNIT_BUILDER", cost = 50, turns = 5 },
			{ type = "UNIT_TRADER", cost = 40, turns = 4, blocked = { "Your Civilization needs more Trade Route capacity." } },
			{ type = "UNIT_BLOCKED", cost = 40, turns = 4, blocked = {} },
			{ type = "UNIT_SECRET", cost = 40, turns = 4, hidden = true },
		},
		buildings = {
			{ type = "BUILDING_GRANARY", cost = 60, turns = 6 },
			{ type = "BUILDING_PYRAMIDS", cost = 200, turns = 20, wonder = true, tiles = { { x = 19, y = 20 } } },
		},
		districts = {
			{ type = "DISTRICT_CAMPUS", cost = 54, turns = 6, tiles = { { x = 21, y = 20 } }, purchaseTiles = { { x = 22, y = 21 } } },
			{ type = "DISTRICT_HOLY_SITE", cost = 54, turns = 6, tiles = { { x = 21, y = 21 } }, blocked = { "Requires Population of 13 or greater." } },
			{ type = "DISTRICT_PLACED", cost = 54, turns = 6, placed = true },
		},
		projects = { { type = "PROJECT_SEND_AID", cost = 60, turns = 6 } },
	},
}

describe("SentientSystems_SetProduction", function()
	it("replaces the production with a unit, a building, or a project", function()
		local env = Load(PRODUCER)
		local O = env.CityOperationTypes

		assert.equal("{\"ok\":true}", env.SentientSystems_SetProduction(0, PRODUCER.id, "UNIT_BUILDER"))
		assert.equal("{\"ok\":true}", env.SentientSystems_SetProduction(0, PRODUCER.id, "BUILDING_GRANARY"))
		assert.equal("{\"ok\":true}", env.SentientSystems_SetProduction(0, PRODUCER.id, "PROJECT_SEND_AID"))
		assert.equal(3, #env.requests)

		for index, key in ipairs({ O.PARAM_UNIT_TYPE, O.PARAM_BUILDING_TYPE, O.PARAM_PROJECT_TYPE }) do
			local request = env.requests[index]

			assert.equal(O.BUILD, request.operation)
			assert.equal(O.VALUE_REPLACE_AT, request.parameters[O.PARAM_INSERT_MODE])
			assert.equal(0, request.parameters[O.PARAM_QUEUE_DESTINATION_LOCATION])
			assert.is_number(request.parameters[key])
		end
	end)

	it("fails for a city the player doesn't have", function()
		local env = Load(PRODUCER)

		assert.equal(Failed("Player 0 has no city 9."), env.SentientSystems_SetProduction(0, 9, "UNIT_BUILDER"))
		assert.equal(Failed("Player 3 has no city 9."), env.SentientSystems_SetProduction(3, 9, "UNIT_BUILDER"))
	end)

	it("fails for a name that is no unit, building, district, or project", function()
		local env = Load(PRODUCER)
		local reason = "isn't a unit, building, district, wonder, or project. Use the type of an option of the production choice."

		assert.equal(Failed("UNIT_NOPE " .. reason), env.SentientSystems_SetProduction(0, PRODUCER.id, "UNIT_NOPE"))
		assert.equal(Failed("nil " .. reason), env.SentientSystems_SetProduction(0, PRODUCER.id))
		assert.same({}, env.requests)
	end)

	it("fails for an item that isn't among the city's choices", function()
		local env = Load(PRODUCER)

		assert.equal(Failed("UNIT_SECRET isn't one of this city's production choices."), env.SentientSystems_SetProduction(0, PRODUCER.id, "UNIT_SECRET"))
		assert.same({}, env.requests)
	end)

	it("fails for an item the panel greys out, with the game's reasons", function()
		local env = Load(PRODUCER)

		assert.equal(Failed("This city can't produce UNIT_TRADER now: Your Civilization needs more Trade Route capacity."), env.SentientSystems_SetProduction(0, PRODUCER.id, "UNIT_TRADER"))
		assert.equal(Failed("This city can't produce UNIT_BLOCKED now."), env.SentientSystems_SetProduction(0, PRODUCER.id, "UNIT_BLOCKED"))
		assert.same({}, env.requests)
	end)

	it("places a district or a wonder on a tile of the city", function()
		local env = Load(PRODUCER)
		local O = env.CityOperationTypes

		assert.equal("{\"ok\":true}", env.SentientSystems_SetProduction(0, PRODUCER.id, "DISTRICT_CAMPUS", 21, 20))
		assert.equal("{\"ok\":true}", env.SentientSystems_SetProduction(0, PRODUCER.id, "BUILDING_PYRAMIDS", 19, 20))
		assert.equal(2, #env.requests)
		assert.equal(21, env.requests[1].parameters[O.PARAM_X])
		assert.equal(20, env.requests[1].parameters[O.PARAM_Y])
		assert.is_number(env.requests[1].parameters[O.PARAM_DISTRICT_TYPE])
		assert.equal(O.VALUE_REPLACE_AT, env.requests[1].parameters[O.PARAM_INSERT_MODE])
		assert.equal(19, env.requests[2].parameters[O.PARAM_X])
		assert.is_number(env.requests[2].parameters[O.PARAM_BUILDING_TYPE])
	end)

	it("asks for the tile of a district or a wonder", function()
		local env = Load(PRODUCER)

		assert.equal(Failed("DISTRICT_CAMPUS goes on a tile. Give x and y, from the placement call."), env.SentientSystems_SetProduction(0, PRODUCER.id, "DISTRICT_CAMPUS"))
		assert.equal(Failed("BUILDING_PYRAMIDS goes on a tile. Give x and y, from the placement call."), env.SentientSystems_SetProduction(0, PRODUCER.id, "BUILDING_PYRAMIDS", 19))
		assert.same({}, env.requests)
	end)

	it("fails for a tile that isn't a placement tile, or that the city has to buy first", function()
		local env = Load(PRODUCER)

		assert.equal(Failed("(30, 30) isn't a tile where DISTRICT_CAMPUS can go. Use a tile from the placement call."), env.SentientSystems_SetProduction(0, PRODUCER.id, "DISTRICT_CAMPUS", 30, 30))
		assert.equal(Failed("(22, 21) isn't in the city's territory yet. Buy the tile first."), env.SentientSystems_SetProduction(0, PRODUCER.id, "DISTRICT_CAMPUS", 22, 21))
		assert.same({}, env.requests)
	end)

	it("takes a district the city has placed with no tile", function()
		local env = Load(PRODUCER)

		assert.equal("{\"ok\":true}", env.SentientSystems_SetProduction(0, PRODUCER.id, "DISTRICT_PLACED"))
		assert.is_nil(env.requests[1].parameters[env.CityOperationTypes.PARAM_X])
	end)

	it("gives the game's reasons when it won't start a district on a good tile", function()
		local env = Load(With(PRODUCER, { operationBlocked = true }))

		assert.equal(Failed("This city can't produce DISTRICT_HOLY_SITE now: Requires Population of 13 or greater."), env.SentientSystems_SetProduction(0, PRODUCER.id, "DISTRICT_HOLY_SITE", 21, 21))
		assert.equal(Failed("The game won't start DISTRICT_CAMPUS in this city."), env.SentientSystems_SetProduction(0, PRODUCER.id, "DISTRICT_CAMPUS", 21, 20))
		assert.same({}, env.requests)
	end)

	it("fails when the game won't start the build", function()
		local env = Load(With(PRODUCER, { operationBlocked = true }))

		assert.equal(Failed("The game won't start UNIT_BUILDER in this city."), env.SentientSystems_SetProduction(0, PRODUCER.id, "UNIT_BUILDER"))
		assert.same({}, env.requests)
	end)
end)

