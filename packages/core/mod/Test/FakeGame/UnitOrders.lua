-- Unit orders. Fakes the stance operations, the wake and delete commands, and a
-- unit's activity, and keeps each request in env.requests. A unit's data has
-- activity, one of SLEEP, HOLD, SENTRY, or OPERATION, and awake when absent,
-- and canEver and canNow, the lists of action names that the game's loose and
-- real checks allow. FakeGame/Units.lua fakes the promote command.

return function(env, world, ctx)
	local ACTIONS = { fortify = 100, sleep = 101, skip = 102, alert = 103, heal = 104 }
	local COMMANDS = { wake = 110, delete = 111 }
	local operationNames, commandNames = {}, {}
	local rows = {}

	for name, hash in pairs(ACTIONS) do
		rows[#rows + 1] = { OperationType = "UNITOPERATION_" .. (name == "skip" and "SKIP_TURN" or name:upper()), Hash = hash }
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
	env.UnitCommandTypes.WAKE = COMMANDS.wake
	env.UnitCommandTypes.DELETE = COMMANDS.delete
	env.UnitCommandTypes.PARAM_PROMOTION_TYPE = 112

	-- Returns whether the list has the name.
	local function Has(list, name)
		for _, item in ipairs(list) do
			if item == name then
				return true
			end
		end

		return false
	end

	local canStartOperation, canStartCommand = env.UnitManager.CanStartOperation, env.UnitManager.CanStartCommand

	env.UnitManager.CanStartOperation = function(unit, operation, target, testOnly)
		local name = operationNames[operation]

		if name == nil then
			return canStartOperation(unit, operation, target, testOnly)
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
	end)
end
