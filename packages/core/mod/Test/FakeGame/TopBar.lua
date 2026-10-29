-- The top bar. A player's culture is its culture per turn, tourism its tourism, favor its Diplomatic
-- Favor, and favorPerTurn its favor per turn, which only Gathering Storm (world.expansion2) has. Each
-- is 0 when missing. trade has active, its outgoing routes, and capacity. Science is in
-- FakeGame/Research.lua, gold and faith in FakeGame/Stores.lua and Income.lua, and era.loyalty in
-- FakeGame.lua.

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

		-- The player's trade routes, from data.trade with active and capacity.
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
