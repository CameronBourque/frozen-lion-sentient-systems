-- Resources. A city-state's minor.resources, each with type, amount, exported, and perTurn, which
-- only Gathering Storm reads, and a major player's resources, each with type, class, amount, the
-- stockpile, cap, reserved, unitDemand, powerDemand, imported, perTurn, cities, and allocation,
-- get rows. A player's hiddenResources lists the resource types its techs don't reveal yet.

return function(env, world, ctx)
	local AddRow, hashes, indexes = ctx.AddRow, ctx.hashes, ctx.indexes

	-- A city-state's and a major player's resources get their rows.
	for _, data in pairs(world.players or {}) do
		for _, resource in ipairs((data.minor or {}).resources or {}) do
			AddRow("Resources", "ResourceType", resource.type)
		end

		for _, resource in ipairs(data.resources or {}) do
			AddRow("Resources", "ResourceType", resource.type)

			local row = env.GameInfo.Resources[indexes[resource.type]]

			hashes[resource.type] = hashes[resource.type] or 6000000 + indexes[resource.type]
			row.Hash = hashes[resource.type]
			row.ResourceClassType = "RESOURCECLASS_" .. resource.class:upper()
			row.Name = "LOC_" .. resource.type .. "_NAME"
		end
	end

	ctx.OnPlayer(function(player, data)
		local hidden = {}

		for _, typeName in ipairs(data.hiddenResources or {}) do
			hidden[hashes[typeName]] = true
		end

		-- The resources a city-state has, from data.minor.resources, each with amount, exported,
		-- and perTurn, which only Gathering Storm reads.
		player.GetResources = function()
			local owned = {}

			for _, resource in ipairs((data.minor or {}).resources or {}) do
				owned[indexes[resource.type]] = resource
			end

			local resources = {
				IsResourceVisible = function(_, hash)
					return not hidden[hash]
				end,
				HasResource = function(_, index)
					return owned[index] ~= nil and (owned[index].amount or 0) > 0
				end,
				HasExportedResource = function(_, index)
					return owned[index] ~= nil and (owned[index].exported or 0) > 0
				end,
				GetResourceAmount = function(_, index)
					return owned[index] and owned[index].amount or 0
				end,
				GetExportedResourceAmount = function(_, index)
					return owned[index] and owned[index].exported or 0
				end,
			}

			if env.GameInfo.Governments_XP2 ~= nil then
				function resources.GetResourceAccumulationPerTurn(_, index)
					return owned[index] and owned[index].perTurn or 0
				end
			end

			-- A major player's resources, from data.resources, each with type, class, amount, the stockpile,
			-- cap, reserved, unitDemand, powerDemand, imported, and perTurn, which are 0 when missing,
			-- cities, a city ID to the amount it extracts, and allocation, a city ID to the amount it gets. A
			-- resource is found by its index, its hash, or its type.
			local mine = data.resources or {}

			local function Find(key)
				for _, resource in ipairs(mine) do
					if key == resource.type or key == indexes[resource.type] or key == hashes[resource.type] then
						return resource
					end
				end

				return {}
			end

			if #mine > 0 then
				function resources.GetResourceAmount(_, key)
					return Find(key).amount or 0
				end
			end

			function resources.GetResourceAllocationCities(_, key)
				local cities = {}

				for id, amount in pairs(Find(key).allocation or {}) do
					cities[#cities + 1] = { CityID = id, AllocationAmount = amount }
				end

				table.sort(cities, function(a, b)
					return a.CityID < b.CityID
				end)

				return cities
			end

			-- Whether a plot's resource can be extracted, from the tile's extractable.
			function resources.IsResourceExtractableAt(_, plot)
				return plot.extractable == true
			end

			if env.GameInfo.Governments_XP2 ~= nil then
				function resources.GetResourceAccumulationPerTurn(_, key)
					return Find(key).perTurn or owned[key] and owned[key].perTurn or 0
				end

				for method, field in pairs({
					GetResourceStockpileCap = "cap",
					GetReservedResourceAmount = "reserved",
					GetUnitResourceDemandPerTurn = "unitDemand",
					GetPowerResourceDemandPerTurn = "powerDemand",
					GetResourceImportPerTurn = "imported",
				}) do
					resources[method] = function(_, key)
						return Find(key)[field] or 0
					end
				end

				function resources.GetResourcesExtractedByCity(_, cityID)
					local extracted = {}

					for _, resource in ipairs(mine) do
						if (resource.cities or {})[cityID] ~= nil then
							extracted[#extracted + 1] = { ResourceType = indexes[resource.type], Amount = resource.cities[cityID] }
						end
					end

					return extracted
				end
			end

			return resources
		end
	end)
end
