-- Escaping spies. A player's escapingSpy is its next escaping spy, with id, name, loot, pursuer, the
-- counterspy's name or "" for the police, x, and y, the tile of the city it escapes from. With one,
-- the four escape districts get rows, with TravelTime 1 to 4.

return function(env, world, ctx)
	local AddRow, indexes, List = ctx.AddRow, ctx.indexes, ctx.List


	-- With an escaping spy, each escape district gets a row, with its travel time and name.
	for _, data in pairs(world.players or {}) do
		if data.escapingSpy ~= nil then
			for i, districtType in ipairs({ "DISTRICT_AERODROME", "DISTRICT_HARBOR", "DISTRICT_COMMERCIAL_HUB", "DISTRICT_CITY_CENTER" }) do
				AddRow("Districts", "DistrictType", districtType)

				local row = env.GameInfo.Districts[indexes[districtType]]

				row.TravelTime = i
				row.Name = "LOC_" .. districtType .. "_NAME"
			end
		end
	end

	env.Cities = {
		-- The city of any player on the tile x, y, where an escaping spy is.
		GetPlotPurchaseCity = function(x, y)
			for id = 0, 63 do
				for _, city in (env.Players[id] and env.Players[id]:GetCities() or List({})):Members() do
					if city:GetX() == x and city:GetY() == y then
						return city
					end
				end
			end
		end,
	}

	-- The player's escaping spy, from data.escapingSpy, which FindID alone finds.
	ctx.OnPlayer(function(player, data)
		local spy = data.escapingSpy
		local GetDiplomacy = player.GetDiplomacy

		function player.GetDiplomacy()
			local diplomacy = GetDiplomacy()

			diplomacy.GetNextEscapingSpyID = function()
				return spy and spy.id or -1
			end

			return diplomacy
		end

		if spy ~= nil then
			local GetUnits = player.GetUnits

			function player.GetUnits()
				local list = GetUnits()
				local findID = list.FindID

				function list.FindID(self, unitID)
					if unitID ~= spy.id then
						return findID(self, unitID)
					end

					return {
						GetID = function()
							return spy.id
						end,
						GetX = function()
							return spy.x
						end,
						GetY = function()
							return spy.y
						end,
						GetName = function()
							return spy.name
						end,
						GetLootName = function()
							return spy.loot
						end,
						GetPursuingSpyName = function()
							return spy.pursuer or ""
						end,
					}
				end

				return list
			end
		end
	end)
end
