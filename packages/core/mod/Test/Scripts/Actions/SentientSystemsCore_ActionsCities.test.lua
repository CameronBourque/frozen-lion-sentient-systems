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
