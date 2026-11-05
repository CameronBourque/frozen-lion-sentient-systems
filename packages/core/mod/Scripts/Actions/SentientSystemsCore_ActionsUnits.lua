-- The unit actions. SentientSystemsCore_Actions.lua loads this file. The calls
-- are in docs/findings/actions/.

-- Returns why a move or an attack on x, y would start a war, or nil. The verb
-- starts the reason. Civ6Common.lua opens a confirmation dialog here, which has
-- no call to answer. The game checks only tiles the player can see.
function SentientSystems_GetWarFailure(playerID, unit, x, y, verb)
	if PlayersVisibility[playerID]:IsVisible(x, y) then
		local wars = CombatManager.IsAttackChangeWarState(unit:GetComponentID(), x, y)

		if wars ~= nil and #wars > 0 then
			return verb .. " there would start a war with player " .. wars[1] .. "."
		end
	end

	return nil
end

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
		return "Air units can't move. They rebase, deploy, or attack instead."
	end

	if unit:GetMovesRemaining() <= 0 then
		return "The unit has no moves left."
	end

	local war = SentientSystems_GetWarFailure(playerID, unit, x, y, "Moving")

	if war ~= nil then
		return war
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

-- The unit actions, by name. Each function takes the player ID, the unit, x, y,
-- and type, and returns nil when it worked, and the reason it failed otherwise.
-- The order files add theirs below.
local ACTIONS = {}

function SentientSystems_AddUnitAction(name, action)
	ACTIONS[name] = action
end

SentientSystems_Include("SentientSystemsCore_ActionsUnitStances")
SentientSystems_Include("SentientSystemsCore_ActionsUnitTiles")
SentientSystems_Include("SentientSystemsCore_ActionsUnitJobs")
SentientSystems_Include("SentientSystemsCore_ActionsUnitUpgrade")
SentientSystems_Include("SentientSystemsCore_ActionsUnitFormations")
SentientSystems_Include("SentientSystemsCore_ActionsUnitTileOrders")
SentientSystems_Include("SentientSystemsCore_ActionsUnitAir")
SentientSystems_Include("SentientSystemsCore_ActionsUnitTransport")
SentientSystems_Include("SentientSystemsCore_ActionsUnitAttacks")

-- Returns the names of the unit actions, sorted, for the reason an action name
-- isn't one.
local function GetActionNames()
	local names = {}

	for name in pairs(ACTIONS) do
		names[#names + 1] = name
	end

	table.sort(names)

	return table.concat(names, ", ")
end

-- Gives a unit an order and returns the result as JSON. type is the promotion
-- to take for promote, the improvement to build for improve, and the route to
-- build for build_road. x and y are for the actions that name a tile.
function SentientSystems_UnitAction(playerID, unitID, action, x, y, type)
	return SentientSystems_RunAction("UnitAction", function()
		local unit = UnitManager.GetUnit(playerID, unitID)

		if unit == nil then
			return "Player " .. playerID .. " has no unit " .. unitID .. "."
		end

		if ACTIONS[action] == nil then
			return "Unknown unit action " .. tostring(action) .. ". The actions are " .. GetActionNames() .. "."
		end

		return ACTIONS[action](playerID, unit, x, y, type)
	end)
end
