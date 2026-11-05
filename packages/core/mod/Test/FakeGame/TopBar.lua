-- The top bar. Fakes a player's culture, tourism, favor, and trade routes.
-- FakeGame/Research.lua holds science, and Stores.lua and Income.lua gold and
-- faith.

return function(env, world, ctx)
	ctx.OnPlayer(function(player, data)
		function player.GetStats()
			return {
				GetTourism = function()
					return data.tourism or 0
				end,
			}
		end

		function player.GetFavor()
			return data.favor or 0
		end

		function player.GetTrade()
			local trade = data.trade or {}

			return {
				GetNumOutgoingRoutes = function()
					return trade.active or 0
				end,
				GetOutgoingRouteCapacity = function()
					return trade.capacity or 0
				end,
			}
		end

		function player.GetCulture()
			return {
				GetCultureYield = function()
					return data.culture or 0
				end,
			}
		end

		if world.expansion2 then
			function player.GetFavorPerTurn()
				return data.favorPerTurn or 0
			end
		end
	end)
end
