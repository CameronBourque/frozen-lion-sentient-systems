-- Unit orders: the stance, tile, job, wake, delete, upgrade, and formation
-- orders and a unit's activity. Each request goes in env.requests. A unit's
-- route and reasons are what the game returns. Units.lua fakes promote.

return function(env, world, ctx)
	local ACTIONS = { fortify = 100, sleep = 101, skip = 102, alert = 103, heal = 104, found_city = 105, pillage = 106, pillage_route = 108, found_religion = 130, spread_religion = 131, heal_followers = 132, remove_heresy = 133,
		build_road = 120, remove_feature = 121, harvest = 122, repair = 123, repair_route = 124, remove_improvement = 125 }
	local OPERATION_TYPES = { skip = "SKIP_TURN", heal_followers = "RELIGIOUS_HEAL", found_city = "FOUND_CITY", build_road = "BUILD_ROUTE", harvest = "HARVEST_RESOURCE" }
	local COMMANDS = { wake = 110, delete = 111, upgrade = 113, form_corps = 114, form_army = 115, enter_formation = 116, exit_formation = 117,
		plunder = 144, condemn_heretic = 147, activate = 145, harvest_wonder = 146, building_production = 140, district_production = 141, wonder_production = 142, project_production = 143 }
	local PlotIndex = ctx.PlotIndex
	local operationNames, commandNames = {}, {}
	local rows, upgrades = {}, {}

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
	env.ActivityTypes = { ACTIVITY_AWAKE = 1, ACTIVITY_SLEEP = 2, ACTIVITY_HOLD = 3, ACTIVITY_SENTRY = 4, ACTIVITY_OPERATION = 5, ACTIVITY_HEAL = 6, ACTIVITY_INTERCEPT = 7 }
	env.OperationResultsTypes = { NO_TARGETS = 1, ALL = 2 }
	env.UnitOperationResults = { IMPROVEMENTS = 20, ROUTE_TYPE = 21, FAILURE_REASONS = 22 }
	env.GameInfo.Route_ValidBuildUnits = ctx.Callable({ { RouteType = "ROUTE_ANCIENT_ROAD", UnitType = "UNIT_MILITARY_ENGINEER" } })
	env.UnitOperationTypes.BUILD_IMPROVEMENT = 6
	env.UnitOperationTypes.PARAM_IMPROVEMENT_TYPE = 7
	env.UnitCommandTypes.WAKE = COMMANDS.wake
	env.UnitCommandTypes.PLUNDER_TRADE_ROUTE = COMMANDS.plunder
	env.UnitCommandTypes.CONDEMN_HERETIC = COMMANDS.condemn_heretic
	env.UnitCommandTypes.DELETE = COMMANDS.delete
	env.UnitCommandTypes.UPGRADE = COMMANDS.upgrade
	env.UnitCommandTypes.FORM_CORPS = COMMANDS.form_corps
	env.UnitCommandTypes.FORM_ARMY = COMMANDS.form_army
	env.UnitCommandTypes.ENTER_FORMATION = COMMANDS.enter_formation
	env.UnitCommandTypes.EXIT_FORMATION = COMMANDS.exit_formation
	env.UnitCommandTypes.PARAM_UNIT_PLAYER = 113
	env.UnitCommandTypes.PARAM_UNIT_ID = 114
	env.UnitCommandResults.UNITS = 829
	env.GameInfo.UnitCommands = ctx.TypedRows({
		[0] = { CommandType = "UNITCOMMAND_FORM_CORPS", PrereqCivic = "CIVIC_NATIONALISM" },
		{ CommandType = "UNITCOMMAND_FORM_ARMY", PrereqCivic = "CIVIC_MOBILIZATION" },
		{ CommandType = "UNITCOMMAND_ENTER_FORMATION" },
		{ CommandType = "UNITCOMMAND_ACTIVATE_GREAT_PERSON", Hash = COMMANDS.activate },
		{ CommandType = "UNITCOMMAND_HARVEST_WONDER", Hash = COMMANDS.harvest_wonder },
		{ CommandType = "UNITCOMMAND_BUILDING_PRODUCTION", Hash = COMMANDS.building_production },
		{ CommandType = "UNITCOMMAND_DISTRICT_PRODUCTION", Hash = COMMANDS.district_production },
		{ CommandType = "UNITCOMMAND_WONDER_PRODUCTION", Hash = COMMANDS.wonder_production },
		{ CommandType = "UNITCOMMAND_PROJECT_PRODUCTION", Hash = COMMANDS.project_production },
	}, "CommandType")
	env.UnitCommandResults.UNIT_TYPE = 827
	env.UnitCommandResults.FAILURE_REASONS = 828
	env.GameInfo.UnitUpgrades = ctx.Callable(upgrades)
	env.UnitCommandTypes.PARAM_PROMOTION_TYPE = 112
	env.GlobalParameters = env.GlobalParameters or {}
	env.GlobalParameters.CITY_MIN_RANGE = 3
	env.GlobalParameters.PILLAGE_MOVEMENT_COST = 3

	for _, data in pairs(world.players or {}) do
		for _, unit in ipairs(data.units or {}) do
			local row = env.GameInfo.Units[ctx.indexes[unit.type]]

			row.FoundCity = unit.type == "UNIT_SETTLER"
			row.BuildCharges = (unit.type == "UNIT_BUILDER" or unit.type == "UNIT_MILITARY_ENGINEER") and 3 or 0
			row.Combat = unit.type == "UNIT_KNIGHT" and 50 or 0
			row.FoundReligion = unit.type == "UNIT_GREAT_PROPHET"
			row.SpreadCharges = unit.type == "UNIT_MISSIONARY" and 3 or 0
			row.ReligiousHealCharges = unit.type == "UNIT_GURU" and 3 or 0
			row.RequiresInquisition = unit.type == "UNIT_INQUISITOR"
			row.FormationClass = unit.formationClass or "FORMATION_CLASS_LAND_COMBAT"

			-- An upgrade is a chain of steps, and a step may need a tech.
			local from = unit.type

			for _, step in ipairs(unit.upgrade and unit.upgrade.steps or {}) do
				ctx.AddRow("Units", "UnitType", step.to)
				upgrades[#upgrades + 1] = { Unit = from, UpgradeUnit = step.to }

				local target = env.GameInfo.Units[ctx.indexes[step.to]]

				target.PrereqTech = step.tech
				target.PrereqCivic = step.civic
				from = step.to
			end

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
		GetFeatureType = function()
			return -1
		end,
		GetResourceType = function()
			return -1
		end,
		GetResourceTypeHash = function()
			return 0
		end,
		GetRouteType = function()
			return -1
		end,
		IsRoutePillaged = function()
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

		return Has(testOnly == true and unit.canEver or unit.canNow, name), {
			[env.UnitOperationResults.ROUTE_TYPE] = unit.route,
			[env.UnitOperationResults.FAILURE_REASONS] = unit.reasons,
		}
	end

	env.UnitManager.CanStartCommand = function(unit, command, testOnly, withResults)
		local name = commandNames[command]

		if name == nil then
			return canStartCommand(unit, command, testOnly, withResults)
		end

		local steps = unit.upgrade and unit.upgrade.steps

		return Has(testOnly == true and unit.canEver or unit.canNow, name), withResults and {
			[env.UnitCommandResults.UNIT_TYPE] = steps and ctx.indexes[steps[#steps].to],
			[env.UnitCommandResults.FAILURE_REASONS] = unit.reasons,
		} or nil
	end

	env.UnitManager.GetCommandTargets = function(unit)
		return { [env.UnitCommandResults.UNITS] = unit.partners }
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
		unit.route = data.route
		unit.reasons = data.reasons
		unit.upgrade = data.upgrade
		unit.partners = data.partners or {}

		function unit.GetBuildCharges()
			return data.charges or 0
		end

		function unit.GetUpgradeCost()
			return data.upgrade and data.upgrade.cost or 0
		end
	end)
end
