-- Spy missions. Fakes a spy's readiness, its trips, and the operations the
-- espionage chooser asks about. FakeGame/Spies.lua holds the escaping spy.

return function(env, world, ctx)
	local AddRow, indexes, PlotIndex = ctx.AddRow, ctx.indexes, ctx.PlotIndex

	local OFFENSIVE = {
		"UNITOPERATION_SPY_GAIN_SOURCES",
		"UNITOPERATION_SPY_LISTENING_POST",
		"UNITOPERATION_SPY_SIPHON_FUNDS",
		"UNITOPERATION_SPY_FOMENT_UNREST",
		"UNITOPERATION_SPY_GREAT_WORK_HEIST",
		"UNITOPERATION_SPY_NEUTRALIZE_GOVERNOR",
	}
	local OTHER = { "UNITOPERATION_SPY_COUNTERSPY", "UNITOPERATION_SPY_TRAVEL_NEW_CITY" }
	local namesByHash = {}

	env.UnitOperationResults.PLOTS = 24

	local ALL = {}

	for _, list in ipairs({ OFFENSIVE, OTHER }) do
		for _, name in ipairs(list) do
			ALL[#ALL + 1] = name
		end
	end

	for i, name in ipairs(ALL) do
		AddRow("UnitOperations", "OperationType", name)

		local row = env.GameInfo.UnitOperations[indexes[name]]

		row.Hash = 3000 + i
		row.Description = "LOC_" .. name .. "_DESCRIPTION"
		row.CategoryInUI = i <= #OFFENSIVE and "OFFENSIVESPY" or "MOVE"
		namesByHash[row.Hash] = name
	end

	for _, data in pairs(world.players or {}) do
		for _, unit in ipairs(data.units or {}) do
			if unit.spy then
				env.GameInfo.Units[indexes[unit.type]].Spy = true
			end
		end
	end

	-- Returns the spy table of the unit, or an empty one.
	local function Spy(unit)
		return unit.spyData or {}
	end

	-- Returns the settings of the operation with the row index, for the unit.
	local function Operation(unit, operationIndex)
		return (Spy(unit).ops or {})[env.GameInfo.UnitOperations[operationIndex].OperationType] or {}
	end

	local canStartOperation = env.UnitManager.CanStartOperation

	env.UnitManager.CanStartOperation = function(unit, hash, target, ...)
		local name = namesByHash[hash]

		if name == nil then
			return canStartOperation(unit, hash, target, ...)
		end

		local operation = (Spy(unit).ops or {})[name]

		if operation == nil then
			return false
		end

		if operation.reasons ~= nil then
			return false, { [env.UnitOperationResults.FAILURE_REASONS] = operation.reasons }
		end

		local plots = {}

		for i, tile in ipairs(operation.plots or {}) do
			plots[i] = PlotIndex(tile.x, tile.y)
		end

		return true, #plots > 0 and { [env.UnitOperationResults.PLOTS] = plots } or nil
	end

	-- Returns the travel entry for a city, or an empty one.
	local function Trip(unit, city)
		for _, trip in ipairs(Spy(unit).travel or {}) do
			if trip.player == city:GetOwner() and trip.id == city:GetID() then
				return trip
			end
		end

		return {}
	end

	env.UnitManager.GetTravelTime = function(unit, city)
		return Trip(unit, city).travel or 0
	end

	env.UnitManager.GetEstablishInCityTime = function(unit, city)
		return Trip(unit, city).establish or 0
	end

	env.UnitManager.GetTimeToComplete = function(operationIndex, unit)
		return Operation(unit, operationIndex).turns or 0
	end

	env.UnitManager.GetResultProbability = function(operationIndex, unit)
		return Operation(unit, operationIndex).chances or {}
	end

	env.UnitManager.GetOperationDetailText = function(operationIndex, unit)
		return Operation(unit, operationIndex).detail or ""
	end

	ctx.OnUnit(function(unit, data)
		unit.spyData = data.spy

		function unit.IsReadyToMove()
			return (data.spy or {}).ready ~= false
		end
	end)
end
