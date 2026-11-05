-- The unit actions. SentientSystemsCore_Actions.lua loads this file. The calls
-- are in docs/findings/game-actions.md.

-- Returns why the unit can't move to x, y, or nil when it can. The game's check
-- for a move gives no reasons and passes any target, so each case is checked
-- here, with the path the game's cursor draws.
local function GetMoveFailure(playerID, unit, x, y)
	if not Map.IsPlot(x, y) then
		return "The tile (" .. x .. ", " .. y .. ") is off the map."
	end

	if x == unit:GetX() and y == unit:GetY() then
		return "The unit is already on that tile."
	end

	-- Air units deploy or attack instead of moving. See Civ6Common.lua.
	if GameInfo.Units[unit:GetUnitType()].Domain == "DOMAIN_AIR" then
		return "Air units can't move with this action."
	end

	if unit:GetMovesRemaining() <= 0 then
		return "The unit has no moves left."
	end

	-- Civ6Common.lua opens a confirmation dialog here and doesn't move.
	if PlayersVisibility[playerID]:IsVisible(x, y) then
		local wars = CombatManager.IsAttackChangeWarState(unit:GetComponentID(), x, y)

		if wars ~= nil and #wars > 0 then
			return "Moving there would start a war with player " .. wars[1] .. "."
		end
	end

	local index = Map.GetPlot(x, y):GetIndex()
	local plots = UnitManager.GetMoveToPathEx(unit, index).plots

	if plots[#plots] ~= index then
		return "The unit has no route to that tile."
	end

	return nil
end

-- Moves the unit to x, y by the game's own path, over as many turns as it
-- takes, and returns the result as JSON. It never attacks: a tile with an enemy
-- unit has no route. A result of ok means the game took the request, not that
-- the unit has arrived.
function SentientSystems_MoveUnit(playerID, unitID, x, y)
	return SentientSystems_RunAction("MoveUnit", function()
		local unit = UnitManager.GetUnit(playerID, unitID)

		if unit == nil then
			return "Player " .. playerID .. " has no unit " .. unitID .. "."
		end

		local failure = GetMoveFailure(playerID, unit, x, y)

		if failure ~= nil then
			return failure
		end

		local parameters = {
			[UnitOperationTypes.PARAM_X] = x,
			[UnitOperationTypes.PARAM_Y] = y,
			[UnitOperationTypes.PARAM_MODIFIERS] = UnitOperationMoveModifiers.MOVE_IGNORE_UNEXPLORED_DESTINATION,
		}

		if not UnitManager.CanStartOperation(unit, UnitOperationTypes.MOVE_TO, nil, parameters) then
			return "The game won't start that move."
		end

		UnitManager.RequestOperation(unit, UnitOperationTypes.MOVE_TO, parameters)
	end)
end

-- The stance actions that are unit operations, by action name. UnitPanel.lua
-- reads each hash from GameInfo.UnitOperations, because UnitOperationTypes
-- lacks sleep, skip, and heal.
local OPERATIONS = {
	fortify = "UNITOPERATION_FORTIFY",
	sleep = "UNITOPERATION_SLEEP",
	skip = "UNITOPERATION_SKIP_TURN",
	alert = "UNITOPERATION_ALERT",
	heal = "UNITOPERATION_HEAL",
}

-- The actions that are unit commands, by action name.
local COMMANDS = { wake = true, delete = true }

-- What a unit is doing, by activity, for the reason it can't take an order.
-- A unit that is awake has no entry.
local ACTIVITIES = {}

-- Fills ACTIVITIES once ActivityTypes exists.
local function GetActivityText(unit)
	if next(ACTIVITIES) == nil then
		ACTIVITIES[ActivityTypes.ACTIVITY_SLEEP] = "sleeping"
		ACTIVITIES[ActivityTypes.ACTIVITY_HOLD] = "skipping its turn"
		ACTIVITIES[ActivityTypes.ACTIVITY_SENTRY] = "fortified or on alert"
		ACTIVITIES[ActivityTypes.ACTIVITY_OPERATION] = "busy with an order"
	end

	return ACTIVITIES[UnitManager.GetActivityType(unit)]
end

-- Returns why a stance action can't start. A unit that isn't awake takes a wake
-- order, when the game allows it. canEver is the game's loose check, which
-- fails only when the unit could never do it.
local function GetStanceFailure(unit, action, canEver)
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

	if not canEver then
		return "This kind of unit can't " .. action .. "."
	end

	return "The unit can't " .. action .. " now."
end

-- Requests a stance action, or returns why it can't start. The panel checks an
-- operation loosely first and then for real, without targets.
local function DoOperation(unit, action)
	local hash = GameInfo.UnitOperations[OPERATIONS[action]].Hash
	local canEver = UnitManager.CanStartOperation(unit, hash, nil, true)

	if not canEver or not UnitManager.CanStartOperation(unit, hash, nil, false, OperationResultsTypes.NO_TARGETS) then
		return GetStanceFailure(unit, action, canEver)
	end

	UnitManager.RequestOperation(unit, hash)

	return nil
end

-- Requests a unit command, or returns why it can't start.
local function DoCommand(unit, action)
	local command = UnitCommandTypes[action:upper()]
	local canEver = UnitManager.CanStartCommand(unit, command, true)

	if not canEver or not UnitManager.CanStartCommand(unit, command, false) then
		return GetStanceFailure(unit, action, canEver)
	end

	UnitManager.RequestCommand(unit, command)

	return nil
end

-- Returns the types of the promotions the unit can pick now.
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
	local promotions = GetPromotions(unit)
	local types = {}

	for _, promotion in ipairs(promotions) do
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

-- Returns the names of the unit actions, sorted, for the reason an action name
-- isn't one.
local function GetActionNames()
	local names = { "promote" }

	for name in pairs(OPERATIONS) do
		names[#names + 1] = name
	end

	for name in pairs(COMMANDS) do
		names[#names + 1] = name
	end

	table.sort(names)

	return table.concat(names, ", ")
end

-- Gives a unit an order and returns the result as JSON. type is the promotion
-- to take for promote. x and y are for the actions that name a tile.
function SentientSystems_UnitAction(playerID, unitID, action, x, y, type)
	return SentientSystems_RunAction("UnitAction", function()
		local unit = UnitManager.GetUnit(playerID, unitID)

		if unit == nil then
			return "Player " .. playerID .. " has no unit " .. unitID .. "."
		end

		if OPERATIONS[action] ~= nil then
			return DoOperation(unit, action)
		end

		if COMMANDS[action] then
			return DoCommand(unit, action)
		end

		if action == "promote" then
			return Promote(unit, type)
		end

		return "Unknown unit action " .. tostring(action) .. ". The actions are " .. GetActionNames() .. "."
	end)
end
