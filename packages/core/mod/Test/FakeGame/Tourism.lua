-- Tourism of a plot. Fakes what the tourism banners read from the player's
-- culture. A plot takes tourism, tourists, and tooltip. A city's tile keeps the
-- tourism that Income.lua gives it.

return function(env, world, ctx)
	local PlotIndex = ctx.PlotIndex

	-- The plot at an index, by its data in the world.
	local byIndex = {}

	for _, data in ipairs(world.plots or {}) do
		byIndex[PlotIndex(data.x, data.y)] = data
	end

	ctx.OnPlayer(function(player)
		local getCulture = player.GetCulture

		function player.GetCulture()
			local culture = getCulture()

			local cityTourism = culture.GetTourismAt

			function culture.GetTourismAt(self, index)
				return (byIndex[index] or {}).tourism or (cityTourism and cityTourism(self, index)) or 0
			end

			function culture.GetTouristsAt(_, index)
				return (byIndex[index] or {}).tourists or 0
			end

			function culture.GetTourismTooltipAt(_, index)
				return (byIndex[index] or {}).tooltip or ""
			end

			return culture
		end
	end)
end
