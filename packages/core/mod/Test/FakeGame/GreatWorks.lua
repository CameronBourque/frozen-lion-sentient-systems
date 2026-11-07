-- Great works. Fakes the slot kinds, creators, themes, and yields that the
-- Great Works screen reads, on top of the buildings in CityBuildings.lua.

return function(env, world, ctx)
	local YIELD_NAMES = ctx.YIELD_NAMES
	local indexes, hashes = ctx.indexes, ctx.hashes

	env.GameInfo.GreatWorkSlotTypes = {}

	-- GameInfo.Yields() lists the yields in index order.
	setmetatable(env.GameInfo.Yields, {
		__call = function()
			local index = -1

			return function()
				index = index + 1

				return env.GameInfo.Yields[index]
			end
		end,
	})

	local themes = {}

	env.GameInfo.Building_GreatWorks = function()
		local i = 0

		return function()
			i = i + 1

			return themes[i]
		end
	end

	local subTypes = {}

	for kind, types in pairs(world.validSubTypes or {}) do
		for _, objectType in ipairs(types) do
			subTypes[#subTypes + 1] = { GreatWorkSlotType = kind, GreatWorkObjectType = objectType }
		end
	end

	env.GameInfo.GreatWork_ValidSubTypes = function()
		local i = 0

		return function()
			i = i + 1

			return subTypes[i]
		end
	end

	-- Adds the row of a slot kind and returns its index.
	local function SlotKind(kind)
		for index, row in pairs(env.GameInfo.GreatWorkSlotTypes) do
			if row.GreatWorkSlotType == kind then
				return index
			end
		end

		local index = #env.GameInfo.GreatWorkSlotTypes + 1

		env.GameInfo.GreatWorkSlotTypes[index] = { GreatWorkSlotType = kind }

		return index
	end

	for _, data in pairs(world.players or {}) do
		for _, city in ipairs(data.cities or {}) do
			for _, district in ipairs(city.districts or {}) do
				for _, building in ipairs(district.buildings or {}) do
					local row = env.GameInfo.Buildings[indexes[building.type]]

					row.Name = "LOC_" .. building.type .. "_NAME"
					row.Hash = hashes[building.type]

					if building.theme or building.rules then
						local theme = { BuildingType = building.type, ThemingBonusDescription = building.theme }

						for column, value in pairs(building.rules or {}) do
							theme[column] = value
						end

						themes[#themes + 1] = theme
					end

					for _, work in ipairs(building.greatWorks or {}) do
						local workRow = env.GameInfo.GreatWorks[indexes[work.type]]

						workRow.GreatWorkObjectType = work.objectType or "GREATWORKOBJECT_WRITING"
						workRow.EraType = work.era
						workRow.Tourism = work.tourism or 0
					end
				end
			end
		end
	end

	-- A work's index is its building's index times 100 plus its slot, as in
	-- CityBuildings.lua, and its owner is the civilization that created it.
	local owners = {}

	for _, data in pairs(world.players or {}) do
		for _, city in ipairs(data.cities or {}) do
			for _, district in ipairs(city.districts or {}) do
				for _, building in ipairs(district.buildings or {}) do
					for slot, work in ipairs(building.greatWorks or {}) do
						owners[indexes[building.type] * 100 + slot - 1] = work.owner
					end
				end
			end
		end
	end

	env.Game.GetGreatWorkPlayer = function(work)
		return owners[work] or 0
	end

	ctx.OnPlayer(function(player, data)
		local getCulture = player.GetCulture

		function player.GetCulture()
			local culture = getCulture()
			local setup = data.theming or {}

			function culture.GetAutoThemedBuilding()
				return setup.autoThemed and indexes[setup.autoThemed] or -1
			end

			function culture.IsAutoThemedEligible()
				return setup.autoEligible == true
			end

			return culture
		end
	end)

	ctx.OnCity(function(city, data)
		local getBuildings = city.GetBuildings

		function city.GetBuildings()
			local buildings = getBuildings()
			local getSlots = buildings.GetNumGreatWorkSlots

			-- The building at index, found by walking the rows that carry it.
			local function Building(index)
				for _, district in ipairs(data.districts or {}) do
					for _, building in ipairs(district.buildings or {}) do
						if indexes[building.type] == index then
							return building
						end
					end
				end
			end

			function buildings.GetNumGreatWorkSlots(_, index)
				return math.max(getSlots(buildings, index), #(Building(index).slotKinds or {}))
			end

			function buildings.GetGreatWorkSlotType(_, index, slot)
				local building = Building(index)
				local kind = (building.slotKinds or {})[slot + 1] or (building.greatWorks[slot + 1] or {}).slotKind

				return SlotKind(kind or "GREATWORKSLOT_WRITING")
			end

			function buildings.GetTurnFromIndex(_, work)
				return Building(math.floor(work / 100)).greatWorks[work % 100 + 1].turn or 0
			end

			function buildings.GetCreatorNameFromIndex(_, work)
				return Building(math.floor(work / 100)).greatWorks[work % 100 + 1].creator
			end

			function buildings.IsBuildingThemedCorrectly(_, index)
				return Building(index).themed == true
			end

			function buildings.GetBuildingYieldFromGreatWorks(_, yieldIndex, index)
				local total = 0

				for _, work in ipairs(Building(index).greatWorks or {}) do
					total = total + ((work.yields or {})[YIELD_NAMES[yieldIndex]] or 0)
				end

				return total
			end

			function buildings.GetBuildingTourismFromGreatWorks(_, religious, index)
				local building = Building(index)
				local total = 0

				for _, work in ipairs(building.greatWorks or {}) do
					total = total + (work.tourism or 0)
				end

				return religious and (building.religiousTourism or 0) or total
			end

			return buildings
		end
	end)
end
