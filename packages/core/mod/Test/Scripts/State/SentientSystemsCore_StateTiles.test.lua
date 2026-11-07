local FakeGame = require("FakeGame")
local Game = require("Game")

-- A small map: a forest on grassland hills, a plain grassland tile, an ocean
-- tile, deer, and iron.
local PLOTS = {
	{ x = 0, y = 0, terrain = "TERRAIN_GRASS_HILLS", feature = "FEATURE_FOREST" },
	{ x = 1, y = 0, terrain = "TERRAIN_GRASS" },
	{ x = 0, y = 1, terrain = "TERRAIN_OCEAN" },
	{ x = 1, y = 1, terrain = "TERRAIN_TUNDRA", resource = "RESOURCE_DEER" },
	{ x = 2, y = 1, terrain = "TERRAIN_PLAINS_HILLS", resource = "RESOURCE_IRON" },
	{
		x = 0, y = 2, terrain = "TERRAIN_PLAINS", owner = 1, district = "DISTRICT_CITY_CENTER",
		route = "ROUTE_ANCIENT_ROAD",
	},
	{
		x = 1, y = 2, terrain = "TERRAIN_GRASS", owner = 1, improvement = "IMPROVEMENT_FARM",
		improvementPillaged = true, route = "ROUTE_ANCIENT_ROAD", routePillaged = true,
	},
	{ x = 2, y = 2, terrain = "TERRAIN_GRASS", owner = 0, improvement = "IMPROVEMENT_FARM" },
}

-- Returns the tiles JSON in the state for player 0, who has revealed and sees
-- the given plots.
local function TilesFor(player, plots)
	local env = Game.new()

	FakeGame.Install(env, { players = { [0] = player }, plots = plots or PLOTS })
	Game.run(env, "Scripts/State/SentientSystemsCore_State.lua")

	return env.SentientSystems_GetState(0):match("\"tiles\":(%b[])")
end

describe("SentientSystems_GetTileStates", function()
	it("lists each revealed tile with its terrain and feature, and whether it is visible now", function()
		assert.equal(
			"[{\"feature\":\"FEATURE_FOREST\",\"terrain\":\"TERRAIN_GRASS_HILLS\",\"visible\":true,\"x\":0,\"y\":0},"
				.. "{\"terrain\":\"TERRAIN_GRASS\",\"visible\":false,\"x\":1,\"y\":0}]",
			TilesFor({ visible = { { 0, 0 } }, revealed = { { 1, 0 } } })
		)
	end)

	it("leaves out a tile the player hasn't revealed", function()
		local tiles = TilesFor({ revealed = { { 1, 0 } } })

		assert.is_nil(tiles:find("TERRAIN_OCEAN", 1, true))
		assert.is_nil(tiles:find("TERRAIN_GRASS_HILLS", 1, true))
	end)

	it("gives an empty list when the player has revealed nothing", function()
		assert.equal("[]", TilesFor({}))
	end)

	it("adds a resource the player can see", function()
		local tiles = TilesFor({ revealed = { { 1, 1 } } })

		assert.equal("[{\"resource\":\"RESOURCE_DEER\",\"terrain\":\"TERRAIN_TUNDRA\",\"visible\":false,\"x\":1,\"y\":1}]", tiles)
	end)

	it("leaves out a resource the player's techs don't reveal yet", function()
		local tiles = TilesFor({ revealed = { { 1, 1 }, { 2, 1 } }, hiddenResources = { "RESOURCE_IRON" } })

		assert.truthy(tiles:find("RESOURCE_DEER", 1, true))
		assert.is_nil(tiles:find("RESOURCE_IRON", 1, true))
		assert.truthy(tiles:find("TERRAIN_PLAINS_HILLS", 1, true))
	end)

	it("adds a tile's owner, district, and road", function()
		assert.equal(
			"[{\"district\":\"DISTRICT_CITY_CENTER\",\"owner\":1,\"route\":\"ROUTE_ANCIENT_ROAD\",\"terrain\":\"TERRAIN_PLAINS\",\"visible\":false,\"x\":0,\"y\":2}]",
			TilesFor({ revealed = { { 0, 2 } } })
		)
	end)

	it("adds an improvement, and marks a pillaged improvement and road", function()
		assert.equal(
			"[{\"improvement\":\"IMPROVEMENT_FARM\",\"improvementPillaged\":true,\"owner\":1,\"route\":\"ROUTE_ANCIENT_ROAD\","
				.. "\"routePillaged\":true,\"terrain\":\"TERRAIN_GRASS\",\"visible\":true,\"x\":1,\"y\":2}]",
			TilesFor({ visible = { { 1, 2 } } })
		)
	end)

	it("leaves out the pillaged flags when nothing is pillaged", function()
		assert.equal(
			"[{\"improvement\":\"IMPROVEMENT_FARM\",\"owner\":0,\"terrain\":\"TERRAIN_GRASS\",\"visible\":true,\"x\":2,\"y\":2}]",
			TilesFor({ visible = { { 2, 2 } } })
		)
	end)

	it("reads only the given player's visibility", function()
		local env = Game.new()

		FakeGame.Install(env, { players = { [0] = {}, [1] = { visible = { { 0, 1 } } } }, plots = PLOTS })
		Game.run(env, "Scripts/State/SentientSystemsCore_State.lua")

		assert.equal("[]", env.SentientSystems_GetState(0):match("\"tiles\":(%b[])"))
		assert.truthy(env.SentientSystems_GetState(1):find("TERRAIN_OCEAN", 1, true))
	end)

	describe("tourism", function()
		local TOOLTIP = "GREAT LIGHTHOUSE[NEWLINE][NEWLINE]Visiting Tourists: 2[NEWLINE][NEWLINE]Travelers are coming.[NEWLINE]"
			.. "Tourism added by this Wonder: +11 [ICON_Tourism] Tourism[NEWLINE][NEWLINE]Lifetime Accumulation: 1,528 [ICON_Tourism] Tourism"

		-- Returns the tiles JSON for one tile that player 0 or another owns.
		local function TourismTile(extra, owner)
			local plot = { x = 0, y = 0, terrain = "TERRAIN_GRASS", owner = owner or 0 }

			for key, value in pairs(extra) do
				plot[key] = value
			end

			return TilesFor({ visible = { { 0, 0 } } }, { plot })
		end

		it("adds the tourism, the tourists, the sources, and the lifetime tourism of a tile with tourism", function()
			local tile = TourismTile({ tourism = 11, tourists = 2, tooltip = TOOLTIP })

			assert.truthy(tile:find("\"lifetime\":1528", 1, true))
			assert.truthy(tile:find("\"sources\":[\"Tourism added by this Wonder: +11 Tourism\"]", 1, true))
			assert.truthy(tile:find("\"tourism\":11", 1, true))
			assert.truthy(tile:find("\"tourists\":2", 1, true))
		end)

		it("lists each source line, and leaves out the tourists when there are none", function()
			local tile = TourismTile({
				tourism = 6,
				tooltip = "CITY CENTER[NEWLINE][NEWLINE]Visiting Tourists: 0[NEWLINE][NEWLINE]Tourists are arriving.[NEWLINE]"
					.. "Tourism added by buildings: +1 [ICON_Tourism] Tourism[NEWLINE]Tourism from Great Works in Palace, +5 [ICON_Tourism] Tourism"
					.. "[NEWLINE][NEWLINE]Lifetime Accumulation: 392 [ICON_Tourism] Tourism",
			})

			assert.truthy(tile:find("\"sources\":[\"Tourism added by buildings: +1 Tourism\",\"Tourism from Great Works in Palace, +5 Tourism\"]", 1, true))
			assert.is_nil(tile:find("tourists", 1, true))
		end)

		it("keeps a short tooltip whole as the sources, with no lifetime", function()
			local tile = TourismTile({ tourism = 3, tourists = 1, tooltip = "TEMPLE[NEWLINE]Something else" })

			assert.truthy(tile:find("\"sources\":[\"TEMPLE\",\"Something else\"]", 1, true))
			assert.is_nil(tile:find("lifetime", 1, true))
		end)

		it("leaves the lifetime out when the last line has no number", function()
			local tile = TourismTile({ tourism = 3, tooltip = "A[NEWLINE]B[NEWLINE]C[NEWLINE]D[NEWLINE]No number here" })

			assert.is_nil(tile:find("lifetime", 1, true))
		end)

		it("leaves out a tile with no tourism, and a tile that another player owns", function()
			assert.is_nil(TourismTile({ tourism = 0, tooltip = TOOLTIP }):find("tourism", 1, true))
			assert.is_nil(TourismTile({ tourism = 11, tooltip = TOOLTIP }, 1):find("tourism", 1, true))
		end)
	end)
end)
