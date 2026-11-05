-- Escaping spies. Fakes a player's next escaping spy, with the four escape
-- districts it needs.

return function(env, world, ctx)
	local AddRow, indexes, List = ctx.AddRow, ctx.indexes, ctx.List


	-- With an escaping spy, each escape district gets a row, with its travel
	-- time and name.
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
		-- The city of any player on the tile x, y, where an escaping spy is, or
		-- that has the tile in its ownedTiles.
		GetPlotPurchaseCity = function(x, y)
			for id = 0, 63 do
				for _, city in (env.Players[id] and env.Players[id]:GetCities() or List({})):Members() do
					local owns = city:GetX() == x and city:GetY() == y

					for _, tile in ipairs(city.ownedTiles or {}) do
						owns = owns or tile.x == x and tile.y == y
					end

					if owns then
						return city
					end
				end
			end
		end,
	}

	ctx.OnCity(function(city, data)
		city.ownedTiles = data.ownedTiles
	end)

	-- The player's escaping spy, from data.escapingSpy, which FindID alone
	-- finds.
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
