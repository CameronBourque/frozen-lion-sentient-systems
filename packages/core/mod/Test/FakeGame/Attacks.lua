-- Attacks. Fakes the ranged, air, and city attack calls, the units and city on
-- a tile, and a unit's strengths. FakeGame/UnitMoves.lua fakes the melee
-- attack and the war check.

return function(env, world, ctx)
	local PlotIndex, MAP_WIDTH = ctx.PlotIndex, ctx.MAP_WIDTH

	env.UnitOperationTypes.RANGE_ATTACK = 8
	env.UnitOperationTypes.AIR_ATTACK = 9
	env.UnitOperationTypes.COASTAL_RAID = 10
	env.UnitOperationResults.PLOTS = 21
	env.UnitOperationResults.MODIFIERS = 22
	env.UnitOperationResults.MODIFIER_IS_TARGET = 23
	env.CityCommandTypes.RANGE_ATTACK = 4010
	env.CityCommandResults.MODIFIERS = 2002
	env.CityCommandResults.MODIFIER_IS_TARGET = 2003

	-- The plot indexes of the tiles in range, and what marks each one, for the
	-- UnitOperationResults or CityCommandResults keys.
	local function Targets(tiles, plots, modifiers, isTarget)
		local results = { [plots] = {}, [modifiers] = {} }

		for i, tile in ipairs(tiles) do
			results[plots][i] = PlotIndex(tile.x, tile.y)
			results[modifiers][i] = tile.target and isTarget or 0
		end

		return results
	end

	-- The units on a plot in any layer, each with the ID of its player. The
	-- game's GetUnitsInPlot leaves out the religious, trade, and spy layers, so
	-- the fake has only the call that asks every layer.
	env.MapLayers = { ANY = -1 }
	env.Units = {
		GetUnitsInPlotLayerID = function(x, y, layer)
			assert(layer == env.MapLayers.ANY, "no fake for this layer")

			local found = {}

			for _, player in pairs(env.Players) do
				for _, unit in player:GetUnits():Members() do
					if unit.GetX() == x and unit.GetY() == y then
						found[#found + 1] = unit
					end
				end
			end

			return found
		end,
	}

	env.CityManager.GetCityAt = function(x, y)
		for _, player in pairs(env.Players) do
			for _, city in player:GetCities():Members() do
				if city.GetX() == x and city.GetY() == y then
					return city
				end
			end
		end
	end

	-- A plot for an index that no data made, with its position.
	local getPlotByIndex = env.Map.GetPlotByIndex

	env.Map.GetPlotByIndex = function(index)
		local found, plot = pcall(getPlotByIndex, index)

		if found then
			return plot
		end

		return {
			GetX = function()
				return index % MAP_WIDTH
			end,
			GetY = function()
				return math.floor(index / MAP_WIDTH)
			end,
		}
	end

	local canStartOperation, getOperationTargets = env.UnitManager.CanStartOperation, env.UnitManager.GetOperationTargets
	local canStartCommand, getCommandTargets = env.CityManager.CanStartCommand, env.CityManager.GetCommandTargets

	env.UnitManager.GetOperationTargets = function(unit, operation)
		local R = env.UnitOperationResults

		-- A coastal raid lists plots only, with no target flag.
		if operation == env.UnitOperationTypes.COASTAL_RAID then
			local plots = {}

			for i, tile in ipairs(unit.raidTiles or {}) do
				plots[i] = PlotIndex(tile.x, tile.y)
			end

			return { [R.PLOTS] = plots }
		end

		assert(operation == env.UnitOperationTypes.RANGE_ATTACK or operation == env.UnitOperationTypes.AIR_ATTACK, "no fake for this operation")

		return Targets(unit.targets, R.PLOTS, R.MODIFIERS, R.MODIFIER_IS_TARGET)
	end

	env.UnitManager.CanStartOperation = function(unit, operation, target, parameters, withResults)
		if operation == env.UnitOperationTypes.RANGE_ATTACK or operation == env.UnitOperationTypes.AIR_ATTACK then
			return not unit.blocked
		end

		return canStartOperation(unit, operation, target, parameters, withResults)
	end

	env.CityManager.GetCommandTargets = function(city, command, parameters)
		if command ~= env.CityCommandTypes.RANGE_ATTACK then
			return getCommandTargets(city, command, parameters)
		end

		local R = env.CityCommandResults

		return Targets(city.attackTargets, R.PLOTS, R.MODIFIERS, R.MODIFIER_IS_TARGET)
	end

	env.CityManager.CanStartCommand = function(city, command, ...)
		if command == env.CityCommandTypes.RANGE_ATTACK then
			return not city.attackBlocked
		end

		return canStartCommand(city, command, ...)
	end

	env.CityManager.RequestCommand = function(city, command, parameters)
		env.requests[#env.requests + 1] = { city = city.GetID(), command = command, parameters = parameters }
	end

	-- The game refuses an operation on a city whose operationBlocked is set.
	env.CityManager.CanStartOperation = function(city)
		return not city.operationBlocked
	end

	env.CityManager.RequestOperation = function(city, operation, parameters)
		env.requests[#env.requests + 1] = { city = city.GetID(), operation = operation, parameters = parameters }
	end

	ctx.OnUnit(function(unit, data)
		unit.targets = data.targets or {}
		unit.raidTiles = data.raidTiles

		function unit.GetCombat()
			return data.combat or 0
		end

		function unit.GetRangedCombat()
			return data.ranged or 0
		end

		function unit.GetBombardCombat()
			return data.bombard or 0
		end

		function unit.GetAttacksRemaining()
			return data.attacks or 0
		end
	end)

	ctx.OnCity(function(city, data)
		city.attackTargets = data.attackTargets or {}
		city.attackBlocked = data.attackBlocked == true
		city.operationBlocked = data.operationBlocked == true
	end)
end
