-- WMDs. Fakes the device rows, a player's stockpile, and the unit and silo
-- strike checks and targets. world.wmds lists the device types, a player's
-- wmds counts each, and a unit's wmdReady and a plot's siloReady can launch.

return function(env, world, ctx)
	local AddRow, indexes, plots, PlotIndex = ctx.AddRow, ctx.indexes, ctx.plots, ctx.PlotIndex

	env.GameInfo.WMDs = ctx.TypedRows({}, "WeaponType")

	for _, weaponType in ipairs(world.wmds or {}) do
		AddRow("WMDs", "WeaponType", weaponType)
		env.GameInfo.WMDs[indexes[weaponType]].Name = "LOC_" .. weaponType .. "_NAME"
	end

	-- Every improvement row has weapon slots in the game, 0 for most.
	for _, data in ipairs(world.plots or {}) do
		if data.improvement ~= nil then
			env.GameInfo.Improvements[indexes[data.improvement]].WeaponSlots = data.weaponSlots or 0
		end

		plots[PlotIndex(data.x, data.y)].silo = data
	end

	env.UnitOperationTypes.WMD_STRIKE = 50
	env.UnitOperationTypes.PARAM_WMD_TYPE = 51
	env.CityCommandTypes.WMD_STRIKE = 4050
	env.CityCommandTypes.PARAM_WMD_TYPE = 4051
	env.CityCommandTypes.PARAM_X0 = 4052
	env.CityCommandTypes.PARAM_Y0 = 4053
	env.CityCommandTypes.PARAM_X1 = 4054
	env.CityCommandTypes.PARAM_Y1 = 4055

	-- Returns the type of the device at a GameInfo.WMDs index.
	local function WeaponType(index)
		return env.GameInfo.WMDs[index].WeaponType
	end

	local function Has(list, name)
		for _, item in ipairs(list or {}) do
			if item == name then
				return true
			end
		end

		return false
	end

	-- The plot indexes of a list of tiles.
	local function Indexes(tiles)
		local list = {}

		for i, tile in ipairs(tiles or {}) do
			list[i] = PlotIndex(tile.x, tile.y)
		end

		return list
	end

	local canStartOperation, getOperationTargets = env.UnitManager.CanStartOperation, env.UnitManager.GetOperationTargets

	-- A unit can launch each device in its wmdReady, with its wmdRefusal as the
	-- reasons for the rest. strikeBlocked refuses the request at a tile.
	env.UnitManager.CanStartOperation = function(unit, operation, target, parameters, ...)
		if operation ~= env.UnitOperationTypes.WMD_STRIKE then
			return canStartOperation(unit, operation, target, parameters, ...)
		end

		if parameters[env.UnitOperationTypes.PARAM_X] ~= nil and unit.strikeBlocked then
			return false
		end

		local ready = Has(unit.wmdReady, WeaponType(parameters[env.UnitOperationTypes.PARAM_WMD_TYPE]))

		return ready, { [env.UnitOperationResults.FAILURE_REASONS] = unit.wmdRefusal }
	end

	env.UnitManager.GetOperationTargets = function(unit, operation, parameters)
		if operation ~= env.UnitOperationTypes.WMD_STRIKE then
			return getOperationTargets(unit, operation, parameters)
		end

		return { [env.UnitOperationResults.PLOTS] = Indexes(unit.wmdTargets) }
	end

	local getCommandTargets, canStartCommand = env.CityManager.GetCommandTargets, env.CityManager.CanStartCommand

	-- The silo at X0, Y0 can hit its plot's siloTargets with each device in its
	-- siloReady, and nothing with the rest.
	env.CityManager.GetCommandTargets = function(city, command, parameters)
		if command ~= env.CityCommandTypes.WMD_STRIKE then
			return getCommandTargets(city, command, parameters)
		end

		local C = env.CityCommandTypes
		local silo = plots[PlotIndex(parameters[C.PARAM_X0], parameters[C.PARAM_Y0])].silo

		if Has(silo.siloReady, WeaponType(parameters[C.PARAM_WMD_TYPE])) then
			return { [env.CityCommandResults.PLOTS] = Indexes(silo.siloTargets) }
		end

		return {}
	end

	-- A city whose strikeBlocked is set refuses the strike request.
	env.CityManager.CanStartCommand = function(city, command, ...)
		if command == env.CityCommandTypes.WMD_STRIKE then
			return not city.strikeBlocked
		end

		return canStartCommand(city, command, ...)
	end

	ctx.OnUnit(function(unit, data)
		unit.wmdReady = data.wmdReady
		unit.wmdRefusal = data.wmdRefusal
		unit.wmdTargets = data.wmdTargets
		unit.strikeBlocked = data.strikeBlocked
	end)

	-- A city's war check reads its startsWar, as a unit's does.
	ctx.OnCity(function(city, data)
		city.strikeBlocked = data.strikeBlocked
		city.startsWar = data.startsWar or {}

		function city.GetComponentID()
			return city
		end
	end)

	ctx.OnPlayer(function(player, data)
		player.GetWMDs = function()
			return {
				GetWeaponCount = function(_, index)
					return (data.wmds or {})[WeaponType(index)] or 0
				end,
			}
		end
	end)
end
