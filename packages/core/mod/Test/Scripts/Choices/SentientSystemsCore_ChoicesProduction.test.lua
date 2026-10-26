local FakeGame = require("FakeGame")
local Game = require("Game")

local SETTLER = { type = "UNIT_SETTLER", cost = 40, turns = 6 }

-- Returns the production choice JSON for player 0, whose one city, Rome, has the given unit options.
local function ProductionWith(units)
	local env = Game.new()

	FakeGame.Install(env, {
		players = { [0] = { cities = { { id = 65536, name = "LOC_CITY_NAME_ROME", x = 17, y = 14, population = 3, options = { units = units } } } } },
		text = { LOC_CITY_NAME_ROME = "Rome" },
	})
	Game.run(env, "Scripts/Choices/SentientSystemsCore_Choices.lua")

	return env.SentientSystems_GetChoices(0):match("\"production\":(%b[])")
end

-- Returns a copy of unit with the fields in changes.
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

describe("SentientSystems_GetProductionChoices for units", function()
	it("lists each city by ID and name, with each unit's type, cost, and turns", function()
		assert.equal(
			"[{\"buildings\":[],\"city\":65536,\"districts\":[],\"name\":\"Rome\",\"projects\":[],\"units\":[{\"cost\":40,\"turns\":6,\"type\":\"UNIT_SETTLER\"},{\"cost\":15,\"turns\":2,\"type\":\"UNIT_SCOUT\"}],\"wonders\":[]}]",
			ProductionWith({ SETTLER, { type = "UNIT_SCOUT", cost = 15, turns = 2 } })
		)
	end)

	it("gives an empty list for a city with nothing to produce", function()
		assert.equal("[{\"buildings\":[],\"city\":65536,\"districts\":[],\"name\":\"Rome\",\"projects\":[],\"units\":[],\"wonders\":[]}]", ProductionWith({}))
	end)

	it("adds the progress once there is some", function()
		assert.truthy(ProductionWith({ With(SETTLER, { progress = 12 }) }):find("\"progress\":12", 1, true))
		assert.is_nil(ProductionWith({ With(SETTLER, { progress = 0 }) }):find("progress", 1, true))
	end)

	it("gives the game's reasons for a unit the panel greys out", function()
		assert.equal(
			"[{\"buildings\":[],\"city\":65536,\"districts\":[],\"name\":\"Rome\",\"projects\":[],\"units\":[{\"blocked\":[\"This city needs at least 2 [ICON_Citizen] Population.\"],\"cost\":40,\"turns\":6,\"type\":\"UNIT_SETTLER\"}],\"wonders\":[]}]",
			ProductionWith({ With(SETTLER, { blocked = { "This city needs at least 2 [ICON_Citizen] Population." } }) })
		)
	end)

	it("gives an empty list of reasons for a greyed-out unit the game gives none for", function()
		assert.truthy(ProductionWith({ With(SETTLER, { blocked = {} }) }):find("\"blocked\":[]", 1, true))
	end)

	it("leaves out a unit the panel hides, and one that must be bought", function()
		assert.equal(
			"[{\"buildings\":[],\"city\":65536,\"districts\":[],\"name\":\"Rome\",\"projects\":[],\"units\":[{\"cost\":40,\"turns\":6,\"type\":\"UNIT_SETTLER\"}],\"wonders\":[]}]",
			ProductionWith({ SETTLER, { type = "UNIT_SPEARMAN", cost = 25, turns = 3, hidden = true }, { type = "UNIT_MISSIONARY", cost = 100, turns = 9, mustPurchase = true } })
		)
	end)

	it("adds a corps and an army when the city can train them, each with its own cost, turns, and reasons", function()
		local production = ProductionWith({ {
			type = "UNIT_WARRIOR",
			cost = 20,
			turns = 3,
			corps = { cost = 30, turns = 5 },
			army = { cost = 40, turns = 7, blocked = { "Needs the Mobilization civic." } },
		} })

		assert.truthy(production:find("\"army\":{\"blocked\":[\"Needs the Mobilization civic.\"],\"cost\":40,\"turns\":7},\"corps\":{\"cost\":30,\"turns\":5},\"cost\":20,\"turns\":3", 1, true))
	end)

	it("lists more than one city, in the game's order", function()
		local env = Game.new()

		FakeGame.Install(env, { players = { [0] = { cities = {
			{ id = 65536, name = "Rome", x = 17, y = 14, population = 3, options = { units = { SETTLER } } },
			{ id = 131072, name = "Antium", x = 20, y = 10, population = 1, options = { units = { With(SETTLER, { turns = 20 }) } } },
		} } } })
		Game.run(env, "Scripts/Choices/SentientSystemsCore_Choices.lua")

		assert.truthy(env.SentientSystems_GetChoices(0):find("\"name\":\"Rome\".*\"turns\":6.*\"name\":\"Antium\".*\"turns\":20"))
	end)
end)

local GRANARY = { type = "BUILDING_GRANARY", district = "DISTRICT_CITY_CENTER", cost = 32, turns = 5 }

-- Returns the buildings in the production choice JSON for player 0, whose one city, Rome, has the
-- given building options and production.
local function BuildingsWith(buildings, production)
	local env = Game.new()

	FakeGame.Install(env, { players = { [0] = { cities = { {
		id = 65536, name = "Rome", x = 17, y = 14, population = 3, production = production, options = { buildings = buildings },
	} } } } })
	Game.run(env, "Scripts/Choices/SentientSystemsCore_Choices.lua")

	return env.SentientSystems_GetChoices(0):match("\"buildings\":(%b[])")
end

describe("SentientSystems_GetProductionChoices for buildings", function()
	it("lists each building's type, district, cost, and turns", function()
		assert.equal(
			"[{\"cost\":32,\"district\":\"DISTRICT_CITY_CENTER\",\"turns\":5,\"type\":\"BUILDING_GRANARY\"},"
				.. "{\"cost\":40,\"district\":\"DISTRICT_CITY_CENTER\",\"turns\":6,\"type\":\"BUILDING_WALLS\"}]",
			BuildingsWith({ GRANARY, With(GRANARY, { type = "BUILDING_WALLS", cost = 40, turns = 6 }) })
		)
	end)

	it("gives an empty list for a city with no buildings to produce", function()
		assert.equal("[]", BuildingsWith({}))
	end)

	it("adds the progress once there is some, and the game's reasons for a greyed-out building", function()
		local buildings = BuildingsWith({ With(GRANARY, { progress = 8, blocked = { "Needs a river." } }) })

		assert.truthy(buildings:find("\"blocked\":[\"Needs a river.\"]", 1, true))
		assert.truthy(buildings:find("\"progress\":8", 1, true))
	end)

	it("leaves out a wonder, a hidden building, and the building in production", function()
		assert.equal(
			"[{\"cost\":40,\"district\":\"DISTRICT_CITY_CENTER\",\"turns\":6,\"type\":\"BUILDING_WALLS\"}]",
			BuildingsWith({
				GRANARY,
				With(GRANARY, { type = "BUILDING_WALLS", cost = 40, turns = 6 }),
				{ type = "BUILDING_PYRAMIDS", cost = 110, turns = 18, wonder = true },
				With(GRANARY, { type = "BUILDING_WATER_MILL", hidden = true }),
			}, { type = "BUILDING_GRANARY", turnsLeft = 5 })
		)
	end)

	it("leaves out a building whose district is in production", function()
		assert.equal("[]", BuildingsWith({ With(GRANARY, { type = "BUILDING_LIBRARY", district = "DISTRICT_CAMPUS" }) }, { type = "DISTRICT_CAMPUS", turnsLeft = 4 }))
	end)

	it("lists a building that must be bought only when it is pillaged, to repair it", function()
		local shrine = With(GRANARY, { type = "BUILDING_SHRINE", district = "DISTRICT_HOLY_SITE", mustPurchase = true })

		assert.equal("[]", BuildingsWith({ shrine }))
		assert.equal(
			"[{\"cost\":32,\"district\":\"DISTRICT_HOLY_SITE\",\"repair\":true,\"turns\":5,\"type\":\"BUILDING_SHRINE\"}]",
			BuildingsWith({ With(shrine, { pillaged = true }) })
		)
	end)
end)

local CAMPUS = { type = "DISTRICT_CAMPUS", cost = 29, turns = 6, tiles = { { x = 17, y = 13 } } }

-- Returns a key in the production choice JSON for player 0, whose one city, Rome, has the given
-- options and districts.
local function ChoiceWith(key, options, districts)
	local env = Game.new()

	FakeGame.Install(env, { players = { [0] = { cities = { {
		id = 65536, name = "Rome", x = 17, y = 14, population = 3, options = options, districts = districts,
	} } } } })
	Game.run(env, "Scripts/Choices/SentientSystemsCore_Choices.lua")

	return env.SentientSystems_GetChoices(0):match("\"" .. key .. "\":(%b[])")
end

describe("SentientSystems_GetProductionChoices for districts", function()
	it("lists each district's type, cost, and turns, without its tiles", function()
		assert.equal(
			"[{\"cost\":29,\"turns\":6,\"type\":\"DISTRICT_CAMPUS\"}]",
			ChoiceWith("districts", { districts = { With(CAMPUS, { purchaseTiles = { { x = 19, y = 14, adjacency = { SCIENCE = 3 } } } }) } })
		)
	end)

	it("doesn't grey out a district that has only a tile to buy", function()
		local districts = ChoiceWith("districts", { districts = { With(CAMPUS, { tiles = {}, purchaseTiles = { { x = 19, y = 14 } } }) } })

		assert.is_nil(districts:find("blocked", 1, true))
	end)

	it("leaves out a district the panel shows as built, and lists one placed but not complete", function()
		local options = { districts = { CAMPUS } }

		assert.equal("[]", ChoiceWith("districts", options, { { type = "DISTRICT_CAMPUS", x = 17, y = 13 } }))
		assert.truthy(ChoiceWith("districts", options, { { type = "DISTRICT_CAMPUS", x = 17, y = 13, complete = false } }):find("DISTRICT_CAMPUS", 1, true))
	end)

	it("lists a built district that is pillaged, to repair it", function()
		local districts = ChoiceWith("districts", { districts = { CAMPUS } }, { { type = "DISTRICT_CAMPUS", x = 17, y = 13, pillaged = true } })

		assert.truthy(districts:find("\"repair\":true", 1, true))
	end)

	it("lists a district that may be built more than once, and adds its progress", function()
		local districts = ChoiceWith("districts", { districts = { With(CAMPUS, { type = "DISTRICT_NEIGHBORHOOD", onePerCity = false, progress = 9 }) } }, {
			{ type = "DISTRICT_NEIGHBORHOOD", x = 17, y = 13 },
		})

		assert.truthy(districts:find("\"progress\":9", 1, true))
	end)

	it("leaves out a hidden district and one marked InternalOnly", function()
		assert.equal("[]", ChoiceWith("districts", { districts = {
			With(CAMPUS, { hidden = true }),
			With(CAMPUS, { type = "DISTRICT_WONDER", internalOnly = true }),
		} }))
	end)

	it("greys out a district with no tile that isn't placed, with the game's reasons", function()
		local districts = ChoiceWith("districts", { districts = { With(CAMPUS, { tiles = {} }) } })

		assert.truthy(districts:find("\"blocked\":[]", 1, true))
	end)

	it("doesn't grey out a district with a tile whose only reason is no suitable location", function()
		local districts = ChoiceWith("districts", { districts = { With(CAMPUS, { blocked = { "LOC_DISTRICT_ZONE_NO_SUITABLE_LOCATION" } }) } })

		assert.is_nil(districts:find("blocked", 1, true))
	end)

	it("greys out a district with a tile and another reason", function()
		local districts = ChoiceWith("districts", { districts = { With(CAMPUS, { blocked = { "Needs a population of 4." } }) } })

		assert.truthy(districts:find("\"blocked\":[\"Needs a population of 4.\"]", 1, true))
	end)

	it("doesn't grey out a placed district with no tile, unless its tile is flooded", function()
		local placed = { { type = "DISTRICT_CAMPUS", x = 17, y = 13, complete = false } }

		assert.is_nil(ChoiceWith("districts", { districts = { With(CAMPUS, { tiles = {} }) } }, placed):find("blocked", 1, true))
		assert.truthy(ChoiceWith("districts", { districts = { With(CAMPUS, { tiles = {}, reasons = { "LOC_DISTRICT_REPAIR_LOCATION_FLOODED" } }) } }, placed):find("blocked", 1, true))
	end)
end)

describe("SentientSystems_GetProductionChoices for wonders", function()
	local PYRAMIDS = { type = "BUILDING_PYRAMIDS", cost = 110, turns = 18, wonder = true, tiles = {}, purchaseTiles = { { x = 17, y = 17 } } }

	it("lists each wonder's type, cost, and turns, without its tiles", function()
		assert.equal(
			"[{\"cost\":110,\"turns\":18,\"type\":\"BUILDING_PYRAMIDS\"}]",
			ChoiceWith("wonders", { buildings = { PYRAMIDS } })
		)
	end)

	it("doesn't grey out a wonder with no suitable location that has a tile", function()
		local wonders = ChoiceWith("wonders", { buildings = { With(PYRAMIDS, { blocked = { "No suitable location to construct this." }, noLocation = true }) } })

		assert.is_nil(wonders:find("blocked", 1, true))
	end)

	it("greys out a wonder with no suitable location and no tile, or with another reason", function()
		local noTile = With(PYRAMIDS, { purchaseTiles = {}, blocked = { "No suitable location to construct this." }, noLocation = true })
		local otherReason = With(PYRAMIDS, { blocked = { "Another city is building it." } })

		assert.truthy(ChoiceWith("wonders", { buildings = { noTile } }):find("\"blocked\":[\"No suitable location to construct this.\"]", 1, true))
		assert.truthy(ChoiceWith("wonders", { buildings = { otherReason } }):find("\"blocked\":[\"Another city is building it.\"]", 1, true))
	end)
end)

describe("SentientSystems_GetProductionChoices for projects", function()
	local GRANTS = { type = "PROJECT_ENHANCE_DISTRICT_CAMPUS", cost = 14, turns = 3 }

	it("lists each project's type, cost, and turns, and whether it is repeatable", function()
		assert.equal(
			"[{\"cost\":14,\"repeatable\":true,\"turns\":3,\"type\":\"PROJECT_ENHANCE_DISTRICT_CAMPUS\"},"
				.. "{\"cost\":1000,\"turns\":50,\"type\":\"PROJECT_LAUNCH_EARTH_SATELLITE\"}]",
			ChoiceWith("projects", { projects = { GRANTS, { type = "PROJECT_LAUNCH_EARTH_SATELLITE", cost = 1000, turns = 50, maxPlayerInstances = 1 } } })
		)
	end)

	it("adds the progress once there is some, and the game's reasons for a greyed-out project", function()
		local projects = ChoiceWith("projects", { projects = { With(GRANTS, { progress = 6, blocked = { "Needs a campus." } }) } })

		assert.truthy(projects:find("\"blocked\":[\"Needs a campus.\"]", 1, true))
		assert.truthy(projects:find("\"progress\":6", 1, true))
	end)

	it("leaves out a project the panel hides", function()
		assert.equal("[]", ChoiceWith("projects", { projects = { With(GRANTS, { hidden = true }) } }))
	end)
end)
