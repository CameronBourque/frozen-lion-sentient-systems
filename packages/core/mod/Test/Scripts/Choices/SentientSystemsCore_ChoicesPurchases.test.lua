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
			"[{\"city\":65536,\"faith\":{\"buildings\":[],\"districts\":[],\"units\":[]},\"gold\":{\"buildings\":[{\"cost\":130,\"type\":\"BUILDING_GRANARY\"}],\"districts\":[{\"cost\":195,\"type\":\"DISTRICT_CAMPUS\"}],\"tiles\":[],"
				.. "\"units\":[{\"cost\":100,\"type\":\"UNIT_BUILDER\"}]},\"name\":\"Rome\"}]",
			PurchasesWith({ YIELD_GOLD = {
				units = { BUILDER },
				buildings = { { type = "BUILDING_GRANARY", cost = 130 } },
				districts = { { type = "DISTRICT_CAMPUS", cost = 195 } },
			} })
		)
	end)

	it("gives empty lists for a city that can buy nothing", function()
		assert.equal("[{\"city\":65536,\"faith\":{\"buildings\":[],\"districts\":[],\"units\":[]},\"gold\":{\"buildings\":[],\"districts\":[],\"tiles\":[],\"units\":[]},\"name\":\"Rome\"}]", PurchasesWith({}))
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

	it("lists what the city can buy with faith apart from gold", function()
		local purchases = PurchasesWith({ YIELD_FAITH = {
			units = { { type = "UNIT_MISSIONARY", cost = 100 } },
			buildings = { { type = "BUILDING_TEMPLE", cost = 120 } },
		} })

		assert.equal(
			"[{\"city\":65536,\"faith\":{\"buildings\":[{\"cost\":120,\"type\":\"BUILDING_TEMPLE\"}],\"districts\":[],\"units\":[{\"cost\":100,\"type\":\"UNIT_MISSIONARY\"}]},"
				.. "\"gold\":{\"buildings\":[],\"districts\":[],\"tiles\":[],\"units\":[]},\"name\":\"Rome\"}]",
			purchases
		)
	end)

	it("lists a unit or a building that the game marks for gold, when the city can buy it with faith", function()
		local purchases = PurchasesWith({ YIELD_FAITH = {
			units = { { type = "UNIT_WARRIOR", cost = 160, faithEnabled = true } },
			buildings = { { type = "BUILDING_MONUMENT", cost = 140, faithEnabled = true } },
		} })

		assert.truthy(purchases:find("\"faith\":{\"buildings\":[{\"cost\":140,\"type\":\"BUILDING_MONUMENT\"}],\"districts\":[],\"units\":[{\"cost\":160,\"type\":\"UNIT_WARRIOR\"}]}", 1, true))
	end)

	it("adds the panel's faith text when the player can't afford an item with faith", function()
		local purchases = PurchasesWith({ YIELD_FAITH = { units = { { type = "UNIT_MISSIONARY", cost = 100, cantAfford = true } } } })

		assert.truthy(purchases:find("\"blocked\":[\"LOC_BUILDING_INSUFFICIENT_FAITH\"]", 1, true))
	end)

	it("lists the tiles the city can buy with gold, with each cost", function()
		local env = Game.new()

		FakeGame.Install(env, { players = { [0] = {
			gold = 107,
			cities = { { id = 65536, name = "Rome", x = 17, y = 14, population = 3, options = { purchasable = {
				{ x = 19, y = 14, cost = 30 },
				{ x = 16, y = 12, cost = 45 },
			} } } },
		} } })
		Game.run(env, "Scripts/Choices/SentientSystemsCore_Choices.lua")

		assert.truthy(env.SentientSystems_GetChoices(0):find("\"tiles\":[{\"cost\":45,\"x\":16,\"y\":12},{\"cost\":30,\"x\":19,\"y\":14}]", 1, true))
	end)

	it("gives the lens's tooltip, with the whole gold still needed, for a tile that costs more than the player's gold", function()
		local env = Game.new()

		FakeGame.Install(env, { players = { [0] = {
			gold = 40.5,
			cities = { { id = 65536, name = "Rome", x = 17, y = 14, population = 3, options = { purchasable = {
				{ x = 19, y = 14, cost = 30 },
				{ x = 16, y = 12, cost = 45 },
			} } } },
		} } })
		Game.run(env, "Scripts/Choices/SentientSystemsCore_Choices.lua")

		local choices = env.SentientSystems_GetChoices(0)

		assert.truthy(choices:find("{\"blocked\":[\"LOC_PLOTINFO_YOU_NEED_MORE_GOLD_TO_PURCHASE(5)\"],\"cost\":45,\"x\":16,\"y\":12}", 1, true))
		assert.truthy(choices:find("{\"cost\":30,\"x\":19,\"y\":14}", 1, true))
	end)
end)
