local FakeGame = require("FakeGame")
local Game = require("Game")

-- Returns an environment with the placement file loaded, and player 0's one city, Rome, which has
-- the given options.
local function Load(options)
	local env = Game.new()

	FakeGame.Install(env, { players = { [0] = { cities = { { id = 65536, name = "Rome", x = 17, y = 14, population = 3, options = options } } } } })
	Game.run(env, "Scripts/Placement/SentientSystemsCore_Placement.lua")

	for _, city in env.Players[0]:GetCities():Members() do
		return env, city
	end
end

-- Returns the row of a GameInfo table whose column is typeName.
local function Row(rows, column, typeName)
	for row in rows() do
		if row[column] == typeName then
			return row
		end
	end
end

describe("SentientSystems_GetPurchasablePlots", function()
	it("lists the plot indexes of the tiles the city could buy, in index order", function()
		local env, city = Load({ purchasable = { { x = 19, y = 14 }, { x = 16, y = 12 }, { x = 17, y = 17 } } })

		assert.same({ 1216, 1419, 1717 }, env.SentientSystems_GetPurchasablePlots(city))
	end)

	it("gives an empty list when the city can buy no tile", function()
		local env, city = Load({})

		assert.same({}, env.SentientSystems_GetPurchasablePlots(city))
	end)
end)

describe("SentientSystems_GetDistrictTiles", function()
	it("lists the tiles the city owns and the tiles to buy, with each adjacency bonus", function()
		local env, city = Load({
			districts = { {
				type = "DISTRICT_CAMPUS",
				cost = 29,
				turns = 6,
				tiles = { { x = 17, y = 13, adjacency = { SCIENCE = 1 } }, { x = 16, y = 14 } },
				purchaseTiles = { { x = 19, y = 14, adjacency = { SCIENCE = 3, GOLD = 1 } } },
			} },
			purchasable = { { x = 20, y = 14 } },
		})
		local tiles, purchaseTiles = env.SentientSystems_GetDistrictTiles(city, env.SentientSystems_GetPurchasablePlots(city), Row(env.GameInfo.Districts, "DistrictType", "DISTRICT_CAMPUS"))

		assert.same({ { x = 17, y = 13, adjacency = { science = 1 } }, { x = 16, y = 14 } }, tiles)
		assert.same({ { x = 19, y = 14, adjacency = { science = 3, gold = 1 } } }, purchaseTiles)
	end)
end)

describe("SentientSystems_GetWonderTiles", function()
	it("lists the tiles the city owns and the tiles to buy, with no adjacency", function()
		local env, city = Load({
			buildings = { {
				type = "BUILDING_PYRAMIDS",
				cost = 110,
				turns = 18,
				wonder = true,
				tiles = { { x = 16, y = 15 } },
				purchaseTiles = { { x = 17, y = 17 } },
			} },
			purchasable = { { x = 20, y = 14 } },
		})
		local tiles, purchaseTiles = env.SentientSystems_GetWonderTiles(city, env.SentientSystems_GetPurchasablePlots(city), Row(env.GameInfo.Buildings, "BuildingType", "BUILDING_PYRAMIDS"))

		assert.same({ { x = 16, y = 15 } }, tiles)
		assert.same({ { x = 17, y = 17 } }, purchaseTiles)
	end)
end)

describe("SentientSystems_GetPlacement", function()
	local OPTIONS = {
		districts = { {
			type = "DISTRICT_CAMPUS",
			cost = 29,
			turns = 6,
			tiles = { { x = 17, y = 13, adjacency = { SCIENCE = 1 } } },
			purchaseTiles = { { x = 19, y = 14, adjacency = { SCIENCE = 3 } } },
		} },
		buildings = {
			{ type = "BUILDING_PYRAMIDS", cost = 110, turns = 18, wonder = true, purchaseTiles = { { x = 17, y = 17 } } },
			{ type = "BUILDING_GRANARY", cost = 32, turns = 5 },
		},
	}

	it("gives a district's tiles as JSON, with each adjacency bonus", function()
		local env = Load(OPTIONS)

		assert.equal(
			"{\"purchaseTiles\":[{\"adjacency\":{\"science\":3},\"x\":19,\"y\":14}],\"tiles\":[{\"adjacency\":{\"science\":1},\"x\":17,\"y\":13}]}",
			env.SentientSystems_GetPlacement(0, 65536, "DISTRICT_CAMPUS")
		)
	end)

	it("gives a wonder's tiles as JSON, with empty lists as empty lists", function()
		local env = Load(OPTIONS)

		assert.equal("{\"purchaseTiles\":[{\"x\":17,\"y\":17}],\"tiles\":[]}", env.SentientSystems_GetPlacement(0, 65536, "BUILDING_PYRAMIDS"))
	end)

	it("raises an error for a building that isn't a wonder, and for an unknown type", function()
		local env = Load(OPTIONS)

		assert.has_error(function()
			env.SentientSystems_GetPlacement(0, 65536, "BUILDING_GRANARY")
		end, "BUILDING_GRANARY isn't a district or a wonder")
		assert.has_error(function()
			env.SentientSystems_GetPlacement(0, 65536, "DISTRICT_NOPE")
		end, "DISTRICT_NOPE isn't a district or a wonder")
	end)

	it("raises an error for an ID with no player or city", function()
		local env = Load(OPTIONS)

		assert.has_error(function()
			env.SentientSystems_GetPlacement(5, 65536, "DISTRICT_CAMPUS")
		end, "no player 5")
		assert.has_error(function()
			env.SentientSystems_GetPlacement(0, 7, "DISTRICT_CAMPUS")
		end, "no city 7 for player 0")
	end)

	it("loads the JSON encoder without an ERROR line, so the bridge can stash the tiles", function()
		local env = Load(OPTIONS)

		assert.same({}, env.printed)
		assert.equal(1, env.SentientSystems_Stash(env.SentientSystems_GetPlacement(0, 65536, "DISTRICT_CAMPUS")))
	end)
end)
