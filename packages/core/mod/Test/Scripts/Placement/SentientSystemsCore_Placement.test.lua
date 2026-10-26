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
