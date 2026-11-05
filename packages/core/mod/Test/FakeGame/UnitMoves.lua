-- Unit moves. Fakes the calls a move makes, and keeps each operation requested
-- in env.requests.

return function(env, world, ctx)
	local PlotIndex, MAP_WIDTH = ctx.PlotIndex, ctx.MAP_WIDTH

	env.requests = {}
	env.UnitOperationTypes = { MOVE_TO = 1, PARAM_X = 2, PARAM_Y = 3, PARAM_MODIFIERS = 4 }
	env.UnitOperationMoveModifiers = { NONE = 0, ATTACK = 1, MOVE_IGNORE_UNEXPLORED_DESTINATION = 2 }
	env.Map.IsPlot = function(x, y)
		return x >= 0 and x < MAP_WIDTH and y >= 0 and y < MAP_WIDTH
	end

	for _, data in pairs(world.players or {}) do
		for _, unit in ipairs(data.units or {}) do
			ctx.AddRow("Units", "UnitType", unit.type)
			env.GameInfo.Units[ctx.indexes[unit.type]].Domain = unit.domain or "DOMAIN_LAND"
		end
	end

	env.UnitManager.GetUnit = function(playerID, unitID)
		return env.Players[playerID] and env.Players[playerID]:GetUnits():FindID(unitID)
	end

	-- A route is the target alone, which is all the checks read.
	env.UnitManager.GetMoveToPathEx = function(unit, plotIndex)
		for _, tile in ipairs(unit.paths) do
			if PlotIndex(tile.x, tile.y) == plotIndex then
				return { plots = { plotIndex }, turns = { 1 } }
			end
		end

		return { plots = {}, turns = {} }
	end

	env.UnitManager.CanStartOperation = function(unit)
		return not unit.blocked
	end

	env.UnitManager.RequestOperation = function(unit, operation, parameters)
		env.requests[#env.requests + 1] = { unit = unit.GetID(), operation = operation, parameters = parameters }
	end

	env.CombatManager = {
		IsAttackChangeWarState = function(unit, x, y)
			for _, tile in ipairs(unit.startsWar) do
				if tile.x == x and tile.y == y then
					return { tile.player }
				end
			end

			return {}
		end,
	}

	ctx.OnUnit(function(unit, data)
		unit.paths = data.paths or {}
		unit.blocked = data.blocked == true
		unit.startsWar = data.startsWar or {}

		-- The fake's component ID is the unit itself.
		function unit.GetComponentID()
			return unit
		end
	end)
end
