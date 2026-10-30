-- The build queue. A city's production is { type, turnsLeft }, or { hash, turnsLeft } for a hash that
-- GameInfo.Types doesn't know, or nil for nothing in production. data.options.units lists each unit
-- the build queue knows, with type, cost, turns, progress, which is 0 when missing, blocked, a list
-- of reasons the queue refuses it, hidden, which the queue refuses even when it only tests, and
-- corps and army, each with cost, turns, and blocked. data.options.buildings lists each building the
-- build queue knows, with type, cost, turns, progress, blocked, and hidden in the same way, and
-- pillaged, district, its PrereqDistrict, wonder, and mustPurchase, which go in its GameInfo row. A
-- wonder also has noLocation, the NO_SUITABLE_LOCATION result. data.options.districts lists each
-- district the build queue knows, with type, cost, turns, progress, blocked, hidden, and reasons,
-- which the queue returns when it allows the district. onePerCity, true when missing, and
-- internalOnly go in its GameInfo row. data.options.projects lists each project the build queue
-- knows, with type, cost, turns, progress, blocked, and hidden, and maxPlayerInstances and
-- prereqTech, a tech type, which go in its GameInfo row as MaxPlayerInstances and PrereqTech. Each
-- option gets a GameInfo row, with a hash, and a city's production type gets one in GameInfo.Types. Their tiles are in FakeGame/Placement.lua.

return function(env, world, ctx)
	local hashes, indexes, Formation = ctx.hashes, ctx.indexes, ctx.Formation
	local CITY_COMMAND_RESULTS, CITY_OPERATION_RESULTS = env.CityCommandResults, env.CityOperationResults
	local AddRow = ctx.AddRow

	for _, data in pairs(world.players or {}) do
		for _, city in ipairs(data.cities or {}) do
			local typeName = city.production and city.production.type

			for _, unit in ipairs((city.options or {}).units or {}) do
				AddRow("Units", "UnitType", unit.type)

				local row = env.GameInfo.Units[indexes[unit.type]]

				ctx.NextHash(3000000, unit.type)
				row.Hash = hashes[unit.type]
				row.MustPurchase = unit.mustPurchase == true
			end

			for _, building in ipairs((city.options or {}).buildings or {}) do
				AddRow("Buildings", "BuildingType", building.type)

				local row = env.GameInfo.Buildings[indexes[building.type]]

				ctx.NextHash(3000000, building.type)
				row.Hash = hashes[building.type]
				row.MustPurchase = building.mustPurchase == true
				row.IsWonder = building.wonder == true
				row.PrereqDistrict = building.district
			end

			for _, district in ipairs((city.options or {}).districts or {}) do
				AddRow("Districts", "DistrictType", district.type)

				local row = env.GameInfo.Districts[indexes[district.type]]

				ctx.NextHash(3000000, district.type)
				row.Hash = hashes[district.type]
				row.OnePerCity = district.onePerCity ~= false
				row.InternalOnly = district.internalOnly == true
			end

			for _, project in ipairs((city.options or {}).projects or {}) do
				AddRow("Projects", "ProjectType", project.type)

				local row = env.GameInfo.Projects[indexes[project.type]]

				ctx.NextHash(3000000, project.type)
				row.Hash = hashes[project.type]
				row.MaxPlayerInstances = project.maxPlayerInstances
				row.PrereqTech = project.prereqTech
			end

			if typeName ~= nil then
				ctx.NextHash(1000000, typeName)
				env.GameInfo.Types[hashes[typeName]] = { Type = typeName }
			end
		end
	end

	ctx.OnCity(function(city, data)
		local production = data.production
		local hash = production and (production.hash or hashes[production.type]) or 0

		-- Each option by its hash, its index, and its type.
		local unitsByHash, unitsByIndex = {}, {}
		local buildingsByHash, buildingsByIndex = {}, {}
		local districtsByHash, districtsByIndex, districtsByType = {}, {}, {}
		local projectsByHash, projectsByIndex, projectsByType = {}, {}, {}

		for _, unit in ipairs((data.options or {}).units or {}) do
			unitsByHash[hashes[unit.type]] = unit
			unitsByIndex[indexes[unit.type]] = unit
		end

		for _, building in ipairs((data.options or {}).buildings or {}) do
			buildingsByHash[hashes[building.type]] = building
			buildingsByIndex[indexes[building.type]] = building
		end

		for _, project in ipairs((data.options or {}).projects or {}) do
			projectsByHash[hashes[project.type]] = project
			projectsByIndex[indexes[project.type]] = project
			projectsByType[project.type] = project
		end

		for _, district in ipairs((data.options or {}).districts or {}) do
			districtsByHash[hashes[district.type]] = district
			districtsByIndex[indexes[district.type]] = district
			districtsByType[district.type] = district
		end

		city.GetBuildQueue = function()
			return {
				GetCurrentProductionTypeHash = function()
					return hash
				end,
				-- The game takes a hash or a type name, and a formation for a unit.
				GetTurnsLeft = function(_, typeOrHash, formation)
					local unit = unitsByHash[typeOrHash]

					if unit ~= nil then
						return Formation(unit, formation).turns
					end

					if buildingsByHash[typeOrHash] ~= nil then
						return buildingsByHash[typeOrHash].turns
					end

					if districtsByType[typeOrHash] ~= nil then
						return districtsByType[typeOrHash].turns
					end

					if projectsByType[typeOrHash] ~= nil then
						return projectsByType[typeOrHash].turns
					end

					assert(production and (typeOrHash == hash or typeOrHash == production.type), "no production " .. tostring(typeOrHash))

					return production.turnsLeft
				end,
				-- With testOnly, whether the queue knows the unit or building. Without it, whether the
				-- city can produce it now, and the results: the reasons it can't, and for a unit, whether
				-- a corps or an army can be trained. params is a building's hash, or a table that names a
				-- unit and its formation, as in the game.
				CanProduce = function(_, params, testOnly, withResults)
					if type(params) == "number" then
						local option = buildingsByHash[params] or districtsByHash[params] or projectsByHash[params]

						if testOnly then
							return option ~= nil and not option.hidden
						end

						return option.blocked == nil, {
							[CITY_COMMAND_RESULTS.FAILURE_REASONS] = option.blocked or option.reasons,
							[CITY_OPERATION_RESULTS.NO_SUITABLE_LOCATION] = option.noLocation,
						}
					end

					local unit = unitsByHash[params.UnitType]

					if testOnly then
						return unit ~= nil and not unit.hidden
					end

					assert(withResults == true, "no fake without results")

					local option = Formation(unit, params.MilitaryFormationType)

					return option.blocked == nil, {
						[CITY_COMMAND_RESULTS.FAILURE_REASONS] = option.blocked,
						[CITY_OPERATION_RESULTS.CAN_TRAIN_CORPS] = unit.corps ~= nil or nil,
						[CITY_OPERATION_RESULTS.CAN_TRAIN_ARMY] = unit.army ~= nil or nil,
					}
				end,
				GetUnitCost = function(_, index)
					return unitsByIndex[index].cost
				end,
				GetUnitProgress = function(_, index)
					return unitsByIndex[index].progress or 0
				end,
				GetUnitCorpsCost = function(_, index)
					return unitsByIndex[index].corps.cost
				end,
				GetUnitArmyCost = function(_, index)
					return unitsByIndex[index].army.cost
				end,
				GetBuildingCost = function(_, index)
					return buildingsByIndex[index].cost
				end,
				GetBuildingProgress = function(_, index)
					return buildingsByIndex[index].progress or 0
				end,
				GetDistrictCost = function(_, index)
					return districtsByIndex[index].cost
				end,
				-- 0 for a district the queue doesn't know, such as a built city center.
				GetDistrictProgress = function(_, index)
					return (districtsByIndex[index] or {}).progress or 0
				end,
				GetProjectCost = function(_, index)
					return projectsByIndex[index].cost
				end,
				GetProjectProgress = function(_, index)
					return projectsByIndex[index].progress or 0
				end,
			}
		end
	end)
end
