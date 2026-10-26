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

	return env.SentientSystems_GetChoices(0):match("^{\"production\":(%b[])")
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

describe("SentientSystems_GetProductionChoices", function()
	it("lists each city by ID and name, with each unit's type, cost, and turns", function()
		assert.equal(
			"[{\"city\":65536,\"name\":\"Rome\",\"units\":[{\"cost\":40,\"turns\":6,\"type\":\"UNIT_SETTLER\"},{\"cost\":15,\"turns\":2,\"type\":\"UNIT_SCOUT\"}]}]",
			ProductionWith({ SETTLER, { type = "UNIT_SCOUT", cost = 15, turns = 2 } })
		)
	end)

	it("gives an empty list for a city with nothing to produce", function()
		assert.equal("[{\"city\":65536,\"name\":\"Rome\",\"units\":[]}]", ProductionWith({}))
	end)

	it("adds the progress once there is some", function()
		assert.truthy(ProductionWith({ With(SETTLER, { progress = 12 }) }):find("\"progress\":12", 1, true))
		assert.is_nil(ProductionWith({ With(SETTLER, { progress = 0 }) }):find("progress", 1, true))
	end)

	it("gives the game's reasons for a unit the panel greys out", function()
		assert.equal(
			"[{\"city\":65536,\"name\":\"Rome\",\"units\":[{\"blocked\":[\"This city needs at least 2 [ICON_Citizen] Population.\"],\"cost\":40,\"turns\":6,\"type\":\"UNIT_SETTLER\"}]}]",
			ProductionWith({ With(SETTLER, { blocked = { "This city needs at least 2 [ICON_Citizen] Population." } }) })
		)
	end)

	it("gives an empty list of reasons for a greyed-out unit the game gives none for", function()
		assert.truthy(ProductionWith({ With(SETTLER, { blocked = {} }) }):find("\"blocked\":[]", 1, true))
	end)

	it("leaves out a unit the panel hides, and one that must be bought", function()
		assert.equal(
			"[{\"city\":65536,\"name\":\"Rome\",\"units\":[{\"cost\":40,\"turns\":6,\"type\":\"UNIT_SETTLER\"}]}]",
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
