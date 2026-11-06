-- The unit orders that need no tile: stances, wake, delete, plunder, and
-- promote. The calls are in docs/findings/actions/.

-- The stance actions, by action name, as unit operations. UnitPanel.lua reads
-- each hash from GameInfo.UnitOperations, because UnitOperationTypes lacks
-- sleep, skip, and heal.
local STANCES = {
	fortify = "UNITOPERATION_FORTIFY",
	sleep = "UNITOPERATION_SLEEP",
	skip = "UNITOPERATION_SKIP_TURN",
	alert = "UNITOPERATION_ALERT",
	heal = "UNITOPERATION_HEAL",
}

-- How the reasons say an action, when its name is not the verb.
local VERBS = {
	found_city = "found a city",
	activate = "activate a great person",
	harvest_wonder = "harvest a wonder",
	improve = "build improvements",
	build_road = "build roads",
	remove_feature = "remove features",
	harvest = "harvest resources",
	remove_improvement = "remove improvements",
}

-- What a unit is doing, by activity, for the reason it can't take an order.
-- A unit that is awake has no entry.
local ACTIVITIES = {}

-- Returns what the unit is doing, or nil when it is awake.
local function GetActivityText(unit)
	if next(ACTIVITIES) == nil then
		ACTIVITIES[ActivityTypes.ACTIVITY_SLEEP] = "sleeping"
		ACTIVITIES[ActivityTypes.ACTIVITY_HOLD] = "skipping its turn"
		ACTIVITIES[ActivityTypes.ACTIVITY_SENTRY] = "fortified or on alert"
		ACTIVITIES[ActivityTypes.ACTIVITY_OPERATION] = "busy with an order"
	end

	return ACTIVITIES[UnitManager.GetActivityType(unit)]
end

-- Returns why an order can't start. A unit that isn't awake takes a wake order,
-- when the game allows it. canEver is the game's loose check, which fails only
-- when the unit could never do it. hint, when given, returns a reason that
-- fits the unit's tile, or nil. The order files use this.
function SentientSystems_GetOrderFailure(unit, action, canEver, hint)
	local activity = GetActivityText(unit)

	if action == "wake" then
		return activity == nil and "The unit is already awake." or "The unit can't wake now."
	end

	if activity ~= nil then
		local reason = "The unit is " .. activity .. "."

		if UnitManager.CanStartCommand(unit, UnitCommandTypes.WAKE, false) then
			reason = reason .. " Wake it first."
		end

		return reason
	end

	local verb = VERBS[action] or action

	if not canEver then
		return "This kind of unit can't " .. verb .. "."
	end

	return hint and hint(unit) or "The unit can't " .. verb .. " now."
end

-- Requests a unit operation that takes no parameters, such as a stance, or
-- returns why it can't start. operationType is its GameInfo row. The panel
-- checks an operation loosely first and then for real, without targets. For an
-- order that depends on the tile, the loose check fails with the tile too, so
-- options.kind says whether the kind of unit could ever do it. options.hint is
-- the reason that fits the tile.
function SentientSystems_DoOperation(unit, action, operationType, options)
	local hash = GameInfo.UnitOperations[operationType].Hash
	local kind = options and options.kind
	local canEver

	if kind ~= nil then
		canEver = kind(GameInfo.Units[unit:GetUnitType()])
	else
		canEver = UnitManager.CanStartOperation(unit, hash, nil, true)
	end

	if not canEver or not UnitManager.CanStartOperation(unit, hash, nil, false, OperationResultsTypes.NO_TARGETS) then
		return SentientSystems_GetOrderFailure(unit, action, canEver, options and options.hint)
	end

	UnitManager.RequestOperation(unit, hash)

	return nil
end

-- The commands whose names differ from their action's, by action name.
local COMMAND_NAMES = { plunder = "PLUNDER_TRADE_ROUTE" }

-- Requests a unit command, or returns why it can't start. options.kind says
-- whether the kind of unit could ever do it, for a command whose loose check
-- fails with the tile too, as DoOperation does. options.hint is the reason
-- that fits the tile.
local function DoCommand(unit, action, options)
	local command = UnitCommandTypes[COMMAND_NAMES[action] or action:upper()]
	local kind = options and options.kind
	local canEver

	if kind ~= nil then
		canEver = kind(GameInfo.Units[unit:GetUnitType()])
	else
		canEver = UnitManager.CanStartCommand(unit, command, true)
	end

	if not canEver or not UnitManager.CanStartCommand(unit, command, false) then
		return SentientSystems_GetOrderFailure(unit, action, canEver, options and options.hint)
	end

	UnitManager.RequestCommand(unit, command)

	return nil
end

-- Returns the promotions the unit can pick now, each with its index and type.
local function GetPromotions(unit)
	local canPromote, results = UnitManager.CanStartCommand(unit, UnitCommandTypes.PROMOTE, true, true)
	local promotions = {}

	if canPromote and results ~= nil and results[UnitCommandResults.PROMOTIONS] ~= nil then
		for _, index in ipairs(results[UnitCommandResults.PROMOTIONS]) do
			promotions[#promotions + 1] = { index = index, type = GameInfo.UnitPromotions[index].UnitPromotionType }
		end
	end

	return promotions
end

-- Requests the promotion of that type, or returns why the unit can't take it.
local function Promote(unit, promotionType)
	local types = {}

	for _, promotion in ipairs(GetPromotions(unit)) do
		if promotion.type == promotionType then
			UnitManager.RequestCommand(unit, UnitCommandTypes.PROMOTE, { [UnitCommandTypes.PARAM_PROMOTION_TYPE] = promotion.index })

			return nil
		end

		types[#types + 1] = promotion.type
	end

	if #types == 0 then
		return "The unit has no promotion to pick."
	end

	return "The unit can't take " .. tostring(promotionType) .. ". It can take " .. table.concat(types, ", ") .. "."
end

for action, operationType in pairs(STANCES) do
	SentientSystems_AddUnitAction(action, function(_, unit)
		return SentientSystems_DoOperation(unit, action, operationType)
	end)
end

for _, action in ipairs({ "wake", "delete" }) do
	SentientSystems_AddUnitAction(action, function(_, unit)
		return DoCommand(unit, action)
	end)
end

-- Plunder is the command for an enemy trader on the unit's tile. The game gives
-- no failure reasons for it, so the tile's hint says what it needs.
SentientSystems_AddUnitAction("plunder", function(_, unit)
	return DoCommand(unit, "plunder", {
		kind = function(row)
			return row.Combat > 0 and row.Domain ~= "DOMAIN_AIR"
		end,
		hint = function()
			return "No trade route of a player at war with you is on the tile, or it is immune to plunder."
		end,
	})
end)

SentientSystems_AddUnitAction("promote", function(_, unit, _, _, type)
	return Promote(unit, type)
end)
