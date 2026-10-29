-- Placement tiles. data.options.districts lists, with the entries FakeGame/Production.lua describes,
-- tiles, the tiles where a district can go, and purchaseTiles, the tiles to buy where it can go, each
-- with x, y, and adjacency, a bonus by YieldTypes name. A wonder in data.options.buildings also has
-- tiles and purchaseTiles. data.options.purchasable lists more tiles to buy, by x and y. Each tile
-- gets a plot, and CanHaveDistrict and CanHaveWonder allow a district or wonder on a tile to buy.
-- UI.GetInterfaceModeParameter returns the parameter it is given.

return function(env, world, ctx)
	local hashes, indexes, plots, PlotIndex, YIELD_TYPES = ctx.hashes, ctx.indexes, ctx.plots, ctx.PlotIndex, ctx.YIELD_TYPES
	local CITY_OPERATION_TYPES, CITY_OPERATION_RESULTS = env.CityOperationTypes, env.CityOperationResults
	local CITY_COMMAND_TYPES, CITY_COMMAND_RESULTS = env.CityCommandTypes, env.CityCommandResults

	env.UI = {
		GetInterfaceModeParameter = function(parameter)
			return parameter
		end,
	}

	-- Each placement tile gets a plot, with the adjacency bonuses and the districts and wonders that
	-- CanHaveDistrict and CanHaveWonder allow on it as a tile to buy.
	local adjacencyAt, districtsAt, wondersAt = {}, {}, {}

	-- Adds a fake plot at a tile that world.plots doesn't hold, and returns its index.
	local function PlacementPlot(tile)
		local index = PlotIndex(tile.x, tile.y)

		plots[index] = plots[index] or {
			GetX = function()
				return tile.x
			end,
			GetY = function()
				return tile.y
			end,
		}
		adjacencyAt[index] = adjacencyAt[index] or {}
		districtsAt[index] = districtsAt[index] or {}
		wondersAt[index] = wondersAt[index] or {}

		return index
	end

	for _, data in pairs(world.players or {}) do
		for _, city in ipairs(data.cities or {}) do
			local options = city.options or {}

			for _, district in ipairs(options.districts or {}) do
				for _, list in ipairs({ district.tiles or {}, district.purchaseTiles or {} }) do
					for _, tile in ipairs(list) do
						adjacencyAt[PlacementPlot(tile)][indexes[district.type]] = tile.adjacency
					end
				end

				for _, tile in ipairs(district.purchaseTiles or {}) do
					districtsAt[PlacementPlot(tile)][indexes[district.type]] = true
				end
			end

			for _, building in ipairs(options.buildings or {}) do
				for _, tile in ipairs(building.tiles or {}) do
					PlacementPlot(tile)
				end

				for _, tile in ipairs(building.purchaseTiles or {}) do
					wondersAt[PlacementPlot(tile)][indexes[building.type]] = true
				end
			end

			for _, tile in ipairs(options.purchasable or {}) do
				PlacementPlot(tile)
			end
		end
	end

	for index, plot in pairs(plots) do
		-- The bonus of a district on the plot, for a YieldTypes value.
		function plot.GetAdjacencyYield(_, _, _, districtIndex, yieldType)
			local adjacency = (adjacencyAt[index] or {})[districtIndex] or {}

			for name, value in pairs(YIELD_TYPES) do
				if value == yieldType then
					return adjacency[name] or 0
				end
			end

			return 0
		end

		function plot.CanHaveDistrict(_, districtIndex)
			return (districtsAt[index] or {})[districtIndex] == true
		end

		function plot.CanHaveWonder(_, buildingIndex)
			return (wondersAt[index] or {})[buildingIndex] == true
		end
	end

	ctx.OnCity(function(city, data)
		local districtsByHash, buildingsByHash = {}, {}

		for _, district in ipairs((data.options or {}).districts or {}) do
			districtsByHash[hashes[district.type]] = district
		end

		for _, building in ipairs((data.options or {}).buildings or {}) do
			buildingsByHash[hashes[building.type]] = building
		end

		-- Returns the plot indexes of a list of tiles.
		local function PlotIndexes(tiles)
			local list = {}

			for i, tile in ipairs(tiles or {}) do
				list[i] = PlotIndex(tile.x, tile.y)
			end

			return list
		end

		-- The plot indexes of every tile to buy, each once.
		local purchasable, seen = {}, {}

		for _, option in ipairs((data.options or {}).districts or {}) do
			for _, plotIndex in ipairs(PlotIndexes(option.purchaseTiles)) do
				if not seen[plotIndex] then
					seen[plotIndex] = true
					purchasable[#purchasable + 1] = plotIndex
				end
			end
		end

		for _, option in ipairs((data.options or {}).buildings or {}) do
			for _, plotIndex in ipairs(PlotIndexes(option.purchaseTiles)) do
				if not seen[plotIndex] then
					seen[plotIndex] = true
					purchasable[#purchasable + 1] = plotIndex
				end
			end
		end

		for _, plotIndex in ipairs(PlotIndexes((data.options or {}).purchasable)) do
			if not seen[plotIndex] then
				seen[plotIndex] = true
				purchasable[#purchasable + 1] = plotIndex
			end
		end

		-- The tiles to buy, for the fake CityManager.GetCommandTargets.
		city.purchasable = purchasable

		-- The plot indexes where the district or wonder that params names can go, for the fake
		-- CityManager.GetOperationTargets.
		city.PlacementPlots = function(params)
			local option = districtsByHash[params[CITY_OPERATION_TYPES.PARAM_DISTRICT_TYPE]] or buildingsByHash[params[CITY_OPERATION_TYPES.PARAM_BUILDING_TYPE]]

			return PlotIndexes(option and option.tiles)
		end
	end)

	env.CityManager.GetOperationTargets = function(city, operation, params)
		assert(operation == CITY_OPERATION_TYPES.BUILD, "no fake for this operation")

		return { [CITY_OPERATION_RESULTS.PLOTS] = city.PlacementPlots(params) }
	end

	env.CityManager.GetCommandTargets = function(city, command, params)
		assert(command == CITY_COMMAND_TYPES.PURCHASE and params[CITY_COMMAND_TYPES.PARAM_PLOT_PURCHASE] ~= nil, "no fake for this command")

		return { [CITY_COMMAND_RESULTS.PLOTS] = city.purchasable }
	end
end
