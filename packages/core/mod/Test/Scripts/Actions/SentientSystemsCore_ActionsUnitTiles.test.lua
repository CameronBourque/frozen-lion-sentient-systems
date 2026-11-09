local FakeGame = require("FakeGame")
local Game = require("Game")
local Helpers = require("Helpers")

local Failed, With = Helpers.Failed, Helpers.With

local UNIT = { id = 7405612, type = "UNIT_SETTLER", x = 20, y = 20, moves = 2 }

-- Returns an environment with the actions loaded into a fake game that has
-- player 0 with the unit, the given plots, and the given other players.
local function Load(unit, plots, players)
	local env = Game.new()
	local world = { players = { [0] = { units = { unit }, revealed = { { 18, 20 }, { 12, 20 } } } }, plots = plots }

	for id, data in pairs(players or {}) do
		world.players[id] = data
	end

	FakeGame.Install(env, world)
	Game.run(env, "Scripts/Actions/SentientSystemsCore_Actions.lua")

	return env
end

local function Plot(changes)
	return With({ x = 20, y = 20, terrain = "TERRAIN_GRASS" }, changes or {})
end

local function Hash(env, operationType)
	return env.GameInfo.UnitOperations[operationType].Hash
end

describe("found_city", function()
	local SETTLER = UNIT

	it("requests the operation the game allows", function()
		local env = Load(With(SETTLER, { canNow = { "found_city" } }))

		assert.equal("{\"ok\":true}", env.SentientSystems_UnitAction(0, UNIT.id, "found_city"))
		assert.same({ { unit = UNIT.id, operation = Hash(env, "UNITOPERATION_FOUND_CITY") } }, env.requests)
	end)

	it("fails for a unit that could never found a city", function()
		assert.equal(Failed("This kind of unit can't found a city."), Load(With(UNIT, { type = "UNIT_KNIGHT" })).SentientSystems_UnitAction(0, UNIT.id, "found_city"))
	end)

	it("fails for a unit with no moves left", function()
		assert.equal(Failed("The unit has no moves left."), Load(With(SETTLER, { moves = 0 })).SentientSystems_UnitAction(0, UNIT.id, "found_city"))
	end)

	it("fails on water or an impassable tile", function()
		for _, changes in ipairs({ { water = true }, { impassable = true } }) do
			local env = Load(SETTLER, { Plot(changes) })

			assert.equal(Failed("A city can't be founded on water or an impassable tile."), env.SentientSystems_UnitAction(0, UNIT.id, "found_city"))
		end
	end)

	it("fails on a tile that another player owns, not on one the player owns", function()
		assert.equal(Failed("Another player owns the tile."), Load(SETTLER, { Plot({ owner = 3 }) }).SentientSystems_UnitAction(0, UNIT.id, "found_city"))
		assert.equal(Failed("The unit can't found a city now."), Load(SETTLER, { Plot({ owner = 0 }) }).SentientSystems_UnitAction(0, UNIT.id, "found_city"))
	end)

	it("fails within the minimum range of a city the player knows, by that city's name", function()
		local own = { cities = { { id = 1, name = "LOC_CITY_NAME_BIBRAX", x = 18, y = 20 } } }
		local rival = { cities = { { id = 1, name = "LOC_CITY_NAME_ROME", x = 18, y = 20 } }, minor = false }

		assert.equal(Failed("The tile is within 3 tiles of LOC_CITY_NAME_BIBRAX."), Load(SETTLER, nil, { [0] = With(own, { units = { SETTLER }, revealed = { { 18, 20 } } }) }).SentientSystems_UnitAction(0, UNIT.id, "found_city"))
		assert.equal(Failed("The tile is within 3 tiles of LOC_CITY_NAME_ROME."), Load(SETTLER, nil, { [4] = rival }).SentientSystems_UnitAction(0, UNIT.id, "found_city"))
	end)

	it("doesn't name a city the player hasn't revealed, or one out of range", function()
		local hidden = { cities = { { id = 1, name = "LOC_CITY_NAME_ROME", x = 19, y = 20 } } }
		local far = { cities = { { id = 1, name = "LOC_CITY_NAME_ROME", x = 12, y = 20 } } }

		assert.equal(Failed("The unit can't found a city now."), Load(SETTLER, nil, { [4] = hidden }).SentientSystems_UnitAction(0, UNIT.id, "found_city"))
		assert.equal(Failed("The unit can't found a city now."), Load(SETTLER, nil, { [4] = far }).SentientSystems_UnitAction(0, UNIT.id, "found_city"))
	end)
end)

describe("pillage", function()
	local KNIGHT = With(UNIT, { type = "UNIT_KNIGHT" })

	it("requests the operation the game allows", function()
		local env = Load(With(KNIGHT, { canNow = { "pillage" } }))

		assert.equal("{\"ok\":true}", env.SentientSystems_UnitAction(0, UNIT.id, "pillage"))
		assert.same({ { unit = UNIT.id, operation = Hash(env, "UNITOPERATION_PILLAGE") } }, env.requests)
	end)

	it("fails for a unit that could never pillage", function()
		assert.equal(Failed("This kind of unit can't pillage."), Load(UNIT).SentientSystems_UnitAction(0, UNIT.id, "pillage"))
	end)

	it("explains the tile", function()
		local KNIGHT = With(KNIGHT, { moves = 3 })
		local improved = Plot({ improvement = "IMPROVEMENT_FARM", owner = 3 })
		local function Reason(unit, plot)
			return Load(unit, plot and { plot } or nil).SentientSystems_UnitAction(0, UNIT.id, "pillage")
		end

		assert.equal(Failed("The unit has no moves left."), Reason(With(KNIGHT, { moves = 0 }), improved))
		assert.equal(Failed("Pillaging takes 3 moves, and the unit has 2."), Reason(With(KNIGHT, { moves = 2 }), improved))
		assert.equal(Failed("There is no improvement or road on the tile."), Reason(KNIGHT))
		assert.equal(Failed("Nothing on the tile is left to pillage."), Reason(KNIGHT, With(improved, { improvementPillaged = true })))
		assert.equal(Failed("Nothing on the tile is left to pillage."), Reason(KNIGHT, With(improved, { improvementPillaged = true, route = "ROUTE_ANCIENT_ROAD", routePillaged = true })))
		assert.equal(Failed("The tile is yours."), Reason(KNIGHT, With(improved, { owner = 0 })))
		assert.equal(Failed("The unit can't pillage now."), Reason(KNIGHT, improved))
		assert.equal(Failed("The unit can't pillage now."), Reason(KNIGHT, Plot({ route = "ROUTE_ANCIENT_ROAD", owner = 3 })))
	end)

	it("pillages the road when the game won't pillage the tile and a road is there, and the improvement first", function()
		local road = Load(With(KNIGHT, { canNow = { "pillage_route" } }))
		local both = Load(With(KNIGHT, { canNow = { "pillage", "pillage_route" } }))

		assert.equal("{\"ok\":true}", road.SentientSystems_UnitAction(0, UNIT.id, "pillage"))
		assert.same({ { unit = UNIT.id, operation = Hash(road, "UNITOPERATION_PILLAGE_ROUTE") } }, road.requests)
		assert.equal("{\"ok\":true}", both.SentientSystems_UnitAction(0, UNIT.id, "pillage"))
		assert.same({ { unit = UNIT.id, operation = Hash(both, "UNITOPERATION_PILLAGE") } }, both.requests)
	end)

	it("doesn't pillage a road for a unit that could never pillage", function()
		local env = Load(With(UNIT, { canNow = { "pillage_route" } }))

		assert.equal(Failed("This kind of unit can't pillage."), env.SentientSystems_UnitAction(0, UNIT.id, "pillage"))
		assert.same({}, env.requests)
	end)
end)

describe("improve", function()
	local BUILDER = With(UNIT, {
		type = "UNIT_BUILDER",
		charges = 3,
		canEver = { "improve" },
		improvements = { "IMPROVEMENT_FARM", "IMPROVEMENT_MINE", "IMPROVEMENT_QUARRY" },
		canBuild = { "IMPROVEMENT_FARM", "IMPROVEMENT_MINE" },
	})

	it("requests the improvement by its hash on the unit's tile", function()
		local env = Load(BUILDER)
		local farm = env.GameInfo.Improvements["IMPROVEMENT_FARM"]

		assert.equal("{\"ok\":true}", env.SentientSystems_UnitAction(0, UNIT.id, "improve", nil, nil, "IMPROVEMENT_FARM"))
		assert.same({ { unit = UNIT.id, operation = env.UnitOperationTypes.BUILD_IMPROVEMENT, parameters = {
			[env.UnitOperationTypes.PARAM_X] = 20,
			[env.UnitOperationTypes.PARAM_Y] = 20,
			[env.UnitOperationTypes.PARAM_IMPROVEMENT_TYPE] = farm.Hash,
		} } }, env.requests)
	end)

	it("fails for an improvement it can't build here, and lists the ones it can", function()
		local env = Load(BUILDER)

		assert.equal(Failed("The unit can't build IMPROVEMENT_QUARRY here. It can build IMPROVEMENT_FARM, IMPROVEMENT_MINE."), env.SentientSystems_UnitAction(0, UNIT.id, "improve", nil, nil, "IMPROVEMENT_QUARRY"))
		assert.equal(Failed("The unit can't build nil here. It can build IMPROVEMENT_FARM, IMPROVEMENT_MINE."), env.SentientSystems_UnitAction(0, UNIT.id, "improve"))
		assert.same({}, env.requests)
	end)

	it("fails for a unit that could never build one", function()
		assert.equal(Failed("This kind of unit can't build improvements."), Load(With(BUILDER, { type = "UNIT_SETTLER", canBuild = {} })).SentientSystems_UnitAction(0, UNIT.id, "improve", nil, nil, "IMPROVEMENT_FARM"))
	end)

	it("says why when the unit can build none here", function()
		local function Reason(changes)
			return Load(With(BUILDER, changes)).SentientSystems_UnitAction(0, UNIT.id, "improve", nil, nil, "IMPROVEMENT_FARM")
		end

		assert.equal(Failed("The unit has no moves left."), Reason({ moves = 0, canBuild = {} }))
		assert.equal(Failed("The unit has no build charges left."), Reason({ charges = 0, canBuild = {} }))
		assert.equal(Failed("The unit can't build any improvement here."), Reason({ canBuild = {} }))
	end)

	it("tells a sleeping builder to wake first", function()
		local env = Load(With(BUILDER, { activity = "SLEEP", canBuild = {}, canNow = { "wake" }, canEver = { "improve", "wake" } }))

		assert.equal(Failed("The unit is sleeping. Wake it first."), env.SentientSystems_UnitAction(0, UNIT.id, "improve", nil, nil, "IMPROVEMENT_FARM"))
	end)
end)
