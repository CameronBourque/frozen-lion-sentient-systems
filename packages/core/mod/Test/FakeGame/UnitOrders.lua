-- Unit orders. Fakes the stance, found city, pillage, improve, wake, and delete
-- operations and a unit's activity, and keeps each request in env.requests.
-- FakeGame/Units.lua fakes promote, and FakeGame/Plots.lua the plots.

return function(env, world, ctx)
	local ACTIONS = { fortify = 100, sleep = 101, skip = 102, alert = 103, heal = 104, found_city = 105, pillage = 106 }
	local OPERATION_TYPES = { skip = "SKIP_TURN", found_city = "FOUND_CITY" }
	local COMMANDS = { wake = 110, delete = 111 }
	local PlotIndex = ctx.PlotIndex
	local operationNames, commandNames = {}, {}
	local rows = {}

	for name, hash in pairs(ACTIONS) do
		rows[#rows + 1] = { OperationType = "UNITOPERATION_" .. (OPERATION_TYPES[name] or name:upper()), Hash = hash }
		operationNames[hash] = name
	end

	for name, hash in pairs(COMMANDS) do
		commandNames[hash] = name
	end

	env.GameInfo.UnitOperations = {}

	for i, row in ipairs(rows) do
		env.GameInfo.UnitOperations[i - 1] = row
	end

	ctx.TypedRows(env.GameInfo.UnitOperations, "OperationType")
	env.ActivityTypes = { ACTIVITY_AWAKE = 1, ACTIVITY_SLEEP = 2, ACTIVITY_HOLD = 3, ACTIVITY_SENTRY = 4, ACTIVITY_OPERATION = 5 }
	env.OperationResultsTypes = { NO_TARGETS = 1 }
	env.UnitOperationResults = { IMPROVEMENTS = 20 }
	env.UnitOperationTypes.BUILD_IMPROVEMENT = 6
	env.UnitOperationTypes.PARAM_IMPROVEMENT_TYPE = 7
	env.UnitCommandTypes.WAKE = COMMANDS.wake
	env.UnitCommandTypes.DELETE = COMMANDS.delete
	env.UnitCommandTypes.PARAM_PROMOTION_TYPE = 112
	env.GlobalParameters = env.GlobalParameters or {}
	env.GlobalParameters.CITY_MIN_RANGE = 3

	for _, data in pairs(world.players or {}) do
		for _, unit in ipairs(data.units or {}) do
			local row = env.GameInfo.Units[ctx.indexes[unit.type]]

			row.FoundCity = unit.type == "UNIT_SETTLER"
			row.BuildCharges = unit.type == "UNIT_BUILDER" and 3 or 0
			row.Combat = unit.type == "UNIT_KNIGHT" and 50 or 0

			for _, name in ipairs(unit.improvements or {}) do
				ctx.AddRow("Improvements", "ImprovementType", name)
				env.GameInfo.Improvements[ctx.indexes[name]].Hash = 5000 + ctx.indexes[name]
			end
		end
	end

	ctx.TypedRows(env.GameInfo.Improvements, "ImprovementType")

	local function Has(list, name)
		for _, item in ipairs(list) do
			if item == name then
				return true
			end
		end

		return false
	end

	local EMPTY_PLOT = {
		GetOwner = function()
			return -1
		end,
		GetImprovementType = function()
			return -1
		end,
		IsImprovementPillaged = function()
			return false
		end,
		IsWater = function()
			return false
		end,
		IsImpassable = function()
			return false
		end,
	}

	env.Map.GetPlot = function(x, y)
		local index = PlotIndex(x, y)

		return setmetatable({
			GetIndex = function()
				return index
			end,
		}, { __index = ctx.plots[index] or EMPTY_PLOT })
	end

	env.Map.GetPlotDistance = function(x1, y1, x2, y2)
		return math.max(math.abs(x1 - x2), math.abs(y1 - y2))
	end

	local canStartOperation, canStartCommand = env.UnitManager.CanStartOperation, env.UnitManager.CanStartCommand

	env.UnitManager.CanStartOperation = function(unit, operation, target, testOnly, withResults)
		local name = operationNames[operation]

		if operation == env.UnitOperationTypes.BUILD_IMPROVEMENT then
			local chosen = testOnly[env.UnitOperationTypes.PARAM_IMPROVEMENT_TYPE]

			if chosen ~= nil then
				return Has(unit.canBuild, env.GameInfo.Improvements[chosen].ImprovementType), {}
			end

			local offered = {}

			for i, improvement in ipairs(unit.improvements) do
				offered[i] = ctx.indexes[improvement]
			end

			return Has(unit.canEver, "improve"), { [env.UnitOperationResults.IMPROVEMENTS] = offered }
		end

		if name == nil then
			return canStartOperation(unit, operation, target, testOnly, withResults)
		end

		return Has(testOnly == true and unit.canEver or unit.canNow, name)
	end

	env.UnitManager.CanStartCommand = function(unit, command, testOnly, withResults)
		local name = commandNames[command]

		if name == nil then
			return canStartCommand(unit, command, testOnly, withResults)
		end

		return Has(testOnly == true and unit.canEver or unit.canNow, name)
	end

	env.UnitManager.RequestCommand = function(unit, command, parameters)
		env.requests[#env.requests + 1] = { unit = unit.GetID(), command = command, parameters = parameters }
	end

	env.UnitManager.GetActivityType = function(unit)
		return env.ActivityTypes["ACTIVITY_" .. (unit.activity or "AWAKE")]
	end

	ctx.OnUnit(function(unit, data)
		unit.activity = data.activity
		unit.canEver = data.canEver or {}
		unit.canNow = data.canNow or {}
		unit.improvements = data.improvements or {}
		unit.canBuild = data.canBuild or {}

		function unit.GetBuildCharges()
			return data.charges or 0
		end
	end)
end
