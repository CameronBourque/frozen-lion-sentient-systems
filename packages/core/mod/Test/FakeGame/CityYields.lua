-- A city's yields. data.yields maps a YieldTypes name to its amount, and a missing yield is 0. data.tiles
-- lists the tiles the city owns, each with x, y, worked, yields, and tourism, which FakeGame/Plots.lua
-- and Income.lua read too. data.routes lists the routes the city sends out, each with player, id, the
-- destination city, and yields, a YieldTypes name to the amount it gives this city.

return function(env, world, ctx)
	local YIELD_TYPES = ctx.YIELD_TYPES

	ctx.OnCity(function(city, data)
		city.tiles = data.tiles or {}

		function city.GetYield(_, yieldType)
			for name, value in pairs(YIELD_TYPES) do
				if value == yieldType then
					return (data.yields or {})[name] or 0
				end
			end

			error("no yield type " .. tostring(yieldType))
		end

		function city.GetTrade()
			return {
				GetOutgoingRoutes = function()
					local routes = {}

					for i, route in ipairs(data.routes or {}) do
						local origin = {}

						for name, index in pairs(YIELD_TYPES) do
							origin[#origin + 1] = { YieldIndex = index, Amount = (route.yields or {})[name] or 0 }
						end

						table.sort(origin, function(a, b)
							return a.YieldIndex < b.YieldIndex
						end)
						routes[i] = { DestinationCityPlayer = route.player, DestinationCityID = route.id, OriginYields = origin }
					end

					return routes
				end,
			}
		end

		function city.GetCitizens()
			return {
				IsPlotWorked = function(_, x, y)
					for _, tile in ipairs(data.tiles or {}) do
						if tile.x == x and tile.y == y then
							return tile.worked == true
						end
					end

					return false
				end,
			}
		end
	end)
end
