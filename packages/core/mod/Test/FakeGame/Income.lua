-- A player's income. data.goldPerTurn and data.upkeep are its gold income and upkeep per turn,
-- data.unitDiscount what its units cost less each, and data.faithPerTurn its faith income, each 0 when
-- missing. data.tooltips has the income's text, as gold, faith, and culture, each "" when missing. A tile
-- that a city of the player owns gives GetTourismAt its tourism, from the city's tiles. The gold and
-- faith stores are in FakeGame/Stores.lua, and a city's tiles and income rows in FakeGame/Plots.lua.

return function(env, world, ctx)
	local PlotIndex = ctx.PlotIndex

	ctx.OnPlayer(function(player, data)
		local GetTreasury, GetReligion, GetCulture = player.GetTreasury, player.GetReligion, player.GetCulture

		function player.GetTreasury()
			local treasury = GetTreasury()

			function treasury.GetGoldYield()
				return data.goldPerTurn or 0
			end

			function treasury.GetTotalMaintenance()
				return data.upkeep or 0
			end

			function treasury.GetMaintDiscountPerUnit()
				return data.unitDiscount or 0
			end

			function treasury.GetGoldYieldToolTip()
				return (data.tooltips or {}).gold or ""
			end

			return treasury
		end

		function player.GetReligion()
			local religion = GetReligion()

			function religion.GetFaithYield()
				return data.faithPerTurn or 0
			end

			function religion.GetFaithYieldToolTip()
				return (data.tooltips or {}).faith or ""
			end

			return religion
		end

		function player.GetCulture()
			local culture = GetCulture()

			-- The tourism of a plot, from the tile that a city of the player owns there.
			function culture.GetTourismAt(_, plotIndex)
				for _, city in ipairs(data.cities or {}) do
					for _, tile in ipairs(city.tiles or {}) do
						if PlotIndex(tile.x, tile.y) == plotIndex then
							return tile.tourism or 0
						end
					end
				end

				return 0
			end

			function culture.GetCultureYieldToolTip()
				return (data.tooltips or {}).culture or ""
			end

			return culture
		end
	end)
end
