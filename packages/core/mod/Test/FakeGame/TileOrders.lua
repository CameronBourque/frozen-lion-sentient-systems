-- Tile orders: rebase, deploy, airlift, paradrop, and priority target, their
-- target tiles, and the paradrop type tag. A unit's airTargets hold the tiles
-- for each action, and its canNow says what the game allows.

return function(env, world, ctx)
	local PlotIndex = ctx.PlotIndex
	local OPERATIONS = { [30] = "rebase", [31] = "deploy" }
	local COMMANDS = { [32] = "airlift", [33] = "paradrop", [36] = "priority_target" }

	env.UnitOperationTypes.REBASE = 30
	env.UnitOperationTypes.DEPLOY = 31
	env.UnitCommandTypes.AIRLIFT = 32
	env.UnitCommandTypes.PARADROP = 33
	env.UnitCommandTypes.PARAM_X = 34
	env.UnitCommandTypes.PARAM_Y = 35
	env.UnitCommandTypes.PRIORITY_TARGET = 36
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

	-- Returns the plot indexes of the tiles for the action, and what marks each
	-- one for the order that marks its targets.
	local function Plots(unit, name)
		local plots, modifiers = {}, {}

		for i, tile in ipairs(unit.airTargets[name] or {}) do
			plots[i] = PlotIndex(tile.x, tile.y)
			modifiers[i] = tile.target and env.CityCommandResults.MODIFIER_IS_TARGET or 0
		end

		return plots, modifiers
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

		local plots, modifiers = Plots(unit, COMMANDS[command])

		return { [env.UnitCommandResults.PLOTS] = plots, [env.CityCommandResults.MODIFIERS] = modifiers }
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
