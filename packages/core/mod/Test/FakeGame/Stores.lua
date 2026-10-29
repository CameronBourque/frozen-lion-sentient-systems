-- The gold and faith stores. A player's gold and faith are its balances, each 0 when missing. Each
-- store can afford an item in a city unless the city's purchase option for that yield has cantAfford,
-- which FakeGame/Purchases.lua describes. The income per turn is in FakeGame/Income.lua.

return function(env, world, ctx)
	local yields = env.GameInfo.Yields

	ctx.OnPlayer(function(player, data)
		-- The player's store of a yield, which can afford an item in a city unless the city's purchase
		-- option for it has cantAfford.
		local function Store(yieldIndex)
			return {
				CanAfford = function(_, cityID, hash, formation)
					local option = player.GetCities():FindID(cityID).PurchaseOption(yieldIndex, hash, formation)

					return option == nil or option.cantAfford ~= true
				end,
			}
		end

		function player.GetTreasury()
			local treasury = Store(yields.YIELD_GOLD.Index)

			function treasury.GetGoldBalance()
				return data.gold or 0
			end

			return treasury
		end

		function player.GetReligion()
			local religion = Store(yields.YIELD_FAITH.Index)

			function religion.GetFaithBalance()
				return data.faith or 0
			end

			return religion
		end
	end)
end
