-- A city's buildings. Each district in data.districts has buildings, each with type, built, which is
-- true when missing, pillaged, yields, a YieldTypes name to an amount, and greatWorks, each with
-- type. A slot's great work is numbered by its building and slot, and its type is that great work's
-- GameInfo index. IsPillaged takes an index or a hash, and a building option in data.options.buildings
-- is found by its hash. The build queue's options are in FakeGame/Production.lua.

return function(env, world, ctx)
	local hashes, indexes, Layout = ctx.hashes, ctx.indexes, ctx.Layout

	ctx.OnCity(function(city, data)
		local layout = Layout(data)
		local buildings, buildingsAt = layout.buildings, layout.buildingsAt

		-- Each building option by its hash, which IsPillaged accepts.
		local buildingsByHash = {}

		for _, building in ipairs((data.options or {}).buildings or {}) do
			buildingsByHash[hashes[building.type]] = building
		end

		-- A building's yield for an index and a yield type such as "YIELD_GOLD", from building.yields,
		-- which maps a YieldTypes name to an amount.
		function city.GetBuildingYield(_, index, yieldType)
			return ((buildings[index] or {}).yields or {})[yieldType:gsub("^YIELD_", "")] or 0
		end

		function city.GetBuildings()
			return {
				GetBuildingsAtLocation = function(_, plotIndex)
					return buildingsAt[plotIndex] or {}
				end,
				HasBuilding = function(_, index)
					return buildings[index].built ~= false
				end,
				-- The great works in a building, from building.greatWorks, each with type.
				GetNumGreatWorkSlots = function(_, index)
					return #(buildings[index].greatWorks or {})
				end,
				GetGreatWorkInSlot = function(_, index, slot)
					return (buildings[index].greatWorks or {})[slot + 1] and index * 100 + slot or -1
				end,
				GetGreatWorkTypeFromIndex = function(_, work)
					return indexes[buildings[math.floor(work / 100)].greatWorks[work % 100 + 1].type]
				end,
				IsPillaged = function(_, indexOrHash)
					local building = buildingsByHash[indexOrHash] or buildings[indexOrHash]

					return building ~= nil and building.pillaged == true
				end,
			}
		end
	end)
end
