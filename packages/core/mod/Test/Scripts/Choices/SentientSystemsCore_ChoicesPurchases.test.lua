local FakeGame = require("FakeGame")
local Game = require("Game")

local BUILDER = { type = "UNIT_BUILDER", cost = 100 }
local CANT_AFFORD = "LOC_BUILDING_INSUFFICIENT_FUNDS"

-- Returns the purchase choice JSON for player 0, whose one city, Rome, can buy what purchases holds.
local function PurchasesWith(purchases)
	local env = Game.new()

	FakeGame.Install(env, { players = { [0] = { cities = { { id = 65536, name = "Rome", x = 17, y = 14, population = 3, purchases = purchases } } } } })
	Game.run(env, "Scripts/Choices/SentientSystemsCore_Choices.lua")

	return env.SentientSystems_GetChoices(0):match("\"purchases\":(%b[])")
end

-- Returns a copy of option with the fields in changes.
local function With(option, changes)
	local copy = {}

	for key, value in pairs(option) do
		copy[key] = value
	end

	for key, value in pairs(changes) do
		copy[key] = value
	end

	return copy
end

describe("SentientSystems_GetPurchaseChoices", function()
	it("lists each city with the units, buildings, and districts it can buy with gold, and their costs", function()
		assert.equal(
			"[{\"city\":65536,\"gold\":{\"buildings\":[{\"cost\":130,\"type\":\"BUILDING_GRANARY\"}],\"districts\":[{\"cost\":195,\"type\":\"DISTRICT_CAMPUS\"}],"
				.. "\"units\":[{\"cost\":100,\"type\":\"UNIT_BUILDER\"}]},\"name\":\"Rome\"}]",
			PurchasesWith({ YIELD_GOLD = {
				units = { BUILDER },
				buildings = { { type = "BUILDING_GRANARY", cost = 130 } },
				districts = { { type = "DISTRICT_CAMPUS", cost = 195 } },
			} })
		)
	end)

	it("gives empty lists for a city that can buy nothing", function()
		assert.equal("[{\"city\":65536,\"gold\":{\"buildings\":[],\"districts\":[],\"units\":[]},\"name\":\"Rome\"}]", PurchasesWith({}))
	end)

	it("adds the panel's text when the player can't afford an item", function()
		local purchases = PurchasesWith({ YIELD_GOLD = { units = { With(BUILDER, { cantAfford = true }) } } })

		assert.truthy(purchases:find("{\"blocked\":[\"" .. CANT_AFFORD .. "\"],\"cost\":100,\"type\":\"UNIT_BUILDER\"}", 1, true))
	end)

	it("gives the game's reasons, then the panel's text, for an item the panel greys out", function()
		local purchases = PurchasesWith({ YIELD_GOLD = { buildings = { { type = "BUILDING_LIBRARY", cost = 180, blocked = { "Needs a campus." }, cantAfford = true } } } })

		assert.truthy(purchases:find("\"blocked\":[\"Needs a campus.\",\"" .. CANT_AFFORD .. "\"]", 1, true))
	end)

	it("leaves out an item the panel doesn't list", function()
		local purchases = PurchasesWith({ YIELD_GOLD = { units = { With(BUILDER, { hidden = true }) } } })

		assert.truthy(purchases:find("\"units\":[]", 1, true))
	end)

	it("adds a corps and an army when the city can buy them, each with its own cost and reasons", function()
		local purchases = PurchasesWith({ YIELD_GOLD = { units = { {
			type = "UNIT_WARRIOR",
			cost = 80,
			corps = { cost = 160 },
			army = { cost = 240, cantAfford = true },
		} } } })

		assert.truthy(purchases:find("{\"army\":{\"blocked\":[\"" .. CANT_AFFORD .. "\"],\"cost\":240},\"corps\":{\"cost\":160},\"cost\":80,\"type\":\"UNIT_WARRIOR\"}", 1, true))
	end)

	it("doesn't try a unit or a building that isn't bought with gold", function()
		local purchases = PurchasesWith({ YIELD_FAITH = { units = { { type = "UNIT_MISSIONARY", cost = 100 } } } })

		assert.equal("[{\"city\":65536,\"gold\":{\"buildings\":[],\"districts\":[],\"units\":[]},\"name\":\"Rome\"}]", purchases)
	end)
end)
