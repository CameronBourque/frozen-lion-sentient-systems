-- Upkeep. world.maintenance maps a district or building type to its upkeep, and
-- world.unitMaintenance a unit type to its unit, corps, and army upkeep, each 0 when missing. Every
-- district and building row gets a Maintenance, a Name, and an IsWonder, and every unit row a hash
-- and a Name, so it runs after the features that add rows. A building is a wonder when its city
-- data says so.

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
