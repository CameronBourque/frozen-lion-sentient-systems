-- Air moves. Fakes the rebase and deploy operations, the airlift and paradrop
-- commands, their target tiles, and the paradrop type tag. A unit's airTargets
-- hold the tiles for each action, and its canNow says what the game allows.

return function(env, world, ctx)
	local PlotIndex = ctx.PlotIndex
	local OPERATIONS, COMMANDS = { [30] = "rebase", [31] = "deploy" }, { [32] = "airlift", [33] = "paradrop" }

	env.UnitOperationTypes.REBASE = 30
	env.UnitOperationTypes.DEPLOY = 31
	env.UnitCommandTypes.AIRLIFT = 32
	env.UnitCommandTypes.PARADROP = 33
	env.UnitCommandTypes.PARAM_X = 34
	env.UnitCommandTypes.PARAM_Y = 35
	env.UnitCommandResults.PLOTS = 830

	local tags = {}

	for _, data in pairs(world.players or {}) do
		for _, unit in ipairs(data.units or {}) do
			if unit.paradrop then
				tags[#tags + 1] = { Type = unit.type, Tag = "CLASS_PARADROP" }
			end
		end
	end

	env.GameInfo.TypeTags = ctx.Callable(tags)

	local function Has(list, name)
		for _, item in ipairs(list) do
			if item == name then
				return true
			end
		end

		return false
	end

	-- Returns the plot indexes of the tiles for the action.
	local function Plots(unit, name)
		local plots = {}

		for i, tile in ipairs(unit.airTargets[name] or {}) do
			plots[i] = PlotIndex(tile.x, tile.y)
		end

		return plots
	end

	local getOperationTargets, canStartOperation = env.UnitManager.GetOperationTargets, env.UnitManager.CanStartOperation
	local getCommandTargets, canStartCommand = env.UnitManager.GetCommandTargets, env.UnitManager.CanStartCommand

	env.UnitManager.GetOperationTargets = function(unit, operation)
		if OPERATIONS[operation] == nil then
			return getOperationTargets(unit, operation)
		end

		return { [env.UnitOperationResults.PLOTS] = Plots(unit, OPERATIONS[operation]) }
	end

	env.UnitManager.CanStartOperation = function(unit, operation, ...)
		if OPERATIONS[operation] == nil then
			return canStartOperation(unit, operation, ...)
		end

		return Has(unit.canNow, OPERATIONS[operation])
	end

	env.UnitManager.GetCommandTargets = function(unit, command)
		if COMMANDS[command] == nil then
			return getCommandTargets(unit, command)
		end

		return { [env.UnitCommandResults.PLOTS] = Plots(unit, COMMANDS[command]) }
	end

	env.UnitManager.CanStartCommand = function(unit, command, ...)
		if COMMANDS[command] == nil then
			return canStartCommand(unit, command, ...)
		end

		return Has(unit.canNow, COMMANDS[command])
	end

	ctx.OnUnit(function(unit, data)
		unit.airTargets = data.airTargets or {}
	end)
end
