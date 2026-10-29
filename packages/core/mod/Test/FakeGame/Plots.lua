-- Plots. world.plots lists plots, each with x, y, terrain, feature, resource, owner, district,
-- improvement, improvementPillaged, route, and routePillaged, which are all optional but x, y, and
-- terrain. Each gets its rows and a plot, and the map's plot count covers the highest row. A tile of
-- a city's data.tiles, with x, y, yields, resource, and extractable, gets a plot too, which has only
-- GetX, GetY, GetYield, and GetResourceType. GetCityPlots lists a city's tiles by plot index.

return function(env, world, ctx)
	local AddRow, hashes, indexes, plots = ctx.AddRow, ctx.hashes, ctx.indexes, ctx.plots
	local PlotIndex, MAP_WIDTH, YIELD_NAMES = ctx.PlotIndex, ctx.MAP_WIDTH, ctx.YIELD_NAMES
	local plotCount = 0

	-- The plots that cities own, by index, with the yield each gives for a GameInfo.Yields index.
	local tilePlots = {}

	for _, player in pairs(world.players or {}) do
		for _, city in ipairs(player.cities or {}) do
			for _, tile in ipairs(city.tiles or {}) do
				tilePlots[PlotIndex(tile.x, tile.y)] = {
					GetX = function()
						return tile.x
					end,
					GetY = function()
						return tile.y
					end,
					GetYield = function(_, yieldIndex)
						return (tile.yields or {})[YIELD_NAMES[yieldIndex]] or 0
					end,
					-- The tile's resource, from tile.resource, and whether it can be extracted.
					GetResourceType = function()
						return tile.resource and indexes[tile.resource] or -1
					end,
					extractable = tile.extractable,
				}
			end
		end
	end

	env.Map = {
		GetPlot = function(x, y)
			return {
				GetIndex = function()
					return PlotIndex(x, y)
				end,
			}
		end,
		GetPlotCount = function()
			return plotCount
		end,
		GetPlotByIndex = function(index)
			return plots[index] or assert(tilePlots[index], "no fake plot " .. index)
		end,
		-- The plots a city owns, as the indexes of its data.tiles.
		GetCityPlots = function()
			return {
				GetPurchasedPlots = function(_, city)
					local indexes = {}

					for i, tile in ipairs(city.tiles) do
						indexes[i] = PlotIndex(tile.x, tile.y)
					end

					return indexes
				end,
			}
		end,
	}

	for _, data in ipairs(world.plots or {}) do
		AddRow("Terrains", "TerrainType", data.terrain)

		if data.feature ~= nil then
			AddRow("Features", "FeatureType", data.feature)
		end

		for _, field in ipairs({ { "Districts", "DistrictType", data.district }, { "Improvements", "ImprovementType", data.improvement }, { "Routes", "RouteType", data.route } }) do
			if field[3] ~= nil then
				AddRow(field[1], field[2], field[3])
			end
		end

		if data.resource ~= nil and hashes[data.resource] == nil then
			AddRow("Resources", "ResourceType", data.resource)
			ctx.NextHash(2000000, data.resource)
		end

		local index = PlotIndex(data.x, data.y)

		plotCount = math.max(plotCount, (data.y + 1) * MAP_WIDTH)
		plots[index] = {
			GetX = function()
				return data.x
			end,
			GetY = function()
				return data.y
			end,
			GetTerrainType = function()
				return indexes[data.terrain]
			end,
			-- The game returns -1 for a plot with no feature or resource.
			GetFeatureType = function()
				return data.feature and indexes[data.feature] or -1
			end,
			GetResourceType = function()
				return data.resource and indexes[data.resource] or -1
			end,
			GetResourceTypeHash = function()
				return data.resource and hashes[data.resource] or 0
			end,
			-- The game returns -1 for no owner, district, improvement, or route.
			GetOwner = function()
				return data.owner or -1
			end,
			GetDistrictType = function()
				return data.district and indexes[data.district] or -1
			end,
			GetImprovementType = function()
				return data.improvement and indexes[data.improvement] or -1
			end,
			IsImprovementPillaged = function()
				return data.improvementPillaged == true
			end,
			GetRouteType = function()
				return data.route and indexes[data.route] or -1
			end,
			IsRoutePillaged = function()
				return data.routePillaged == true
			end,
		}
	end
end
