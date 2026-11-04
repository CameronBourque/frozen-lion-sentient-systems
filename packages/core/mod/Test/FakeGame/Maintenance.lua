-- Upkeep. Fakes the upkeep of districts, buildings, and units. It runs after
-- the features that add rows, because it gives each of their rows a Maintenance
-- and a Name.

return function(env, world, ctx)
	local hashes, wonderTypes = ctx.hashes, ctx.wonderTypes

	local unitCosts = {}

	for _, tableName in ipairs({ "Districts", "Buildings" }) do
		for index, row in pairs(env.GameInfo[tableName]) do
			if type(index) == "number" then
				row.Maintenance = (world.maintenance or {})[row.DistrictType or row.BuildingType] or 0
				row.Name = row.Name or "LOC_" .. (row.DistrictType or row.BuildingType) .. "_NAME"
				row.IsWonder = row.IsWonder or wonderTypes[row.BuildingType]
			end
		end
	end

	for index, row in pairs(env.GameInfo.Units) do
		if type(index) == "number" then
			hashes[row.UnitType] = hashes[row.UnitType] or 5000000 + index
			row.Hash = hashes[row.UnitType]
			row.Name = row.Name or "LOC_" .. row.UnitType .. "_NAME"
			unitCosts[row.Hash] = (world.unitMaintenance or {})[row.UnitType] or {}
		end
	end

	env.UnitManager.GetUnitMaintenance = function(hash)
		return unitCosts[hash].unit or 0
	end
	env.UnitManager.GetUnitCorpsMaintenance = function(hash)
		return unitCosts[hash].corps or 0
	end
	env.UnitManager.GetUnitArmyMaintenance = function(hash)
		return unitCosts[hash].army or 0
	end
end
