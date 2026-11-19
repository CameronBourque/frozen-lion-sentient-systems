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

-- Returns whether the path the game's cursor draws for the unit ends on the
-- plot. Right after an action such as founding a city, the game sometimes
-- returns no path, or nothing at all, for a tile it can reach. See
-- docs/findings/actions/move-routes.md.
local function HasRoute(unit, index)
	local path = UnitManager.GetMoveToPathEx(unit, index)
	local plots = path and path.plots or {}

	return plots[#plots] == index
end

-- Returns why the unit can't move to x, y, or nil when it can. The game's check
-- for a move gives no reasons and passes any target, so each case is checked
-- here, with the path the game's cursor draws.
local function GetMoveFailure(playerID, unit, x, y)
	local offMap = SentientSystems_GetOffMapFailure(x, y)

	if offMap ~= nil then
		return offMap
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
	if not HasRoute(unit, index) then
		return "The unit has no route to that tile. If an action just changed the map, such as founding a city, the game may still be updating, so try again."
	end

	return nil
end

local function MoveUnit(playerID, unitID, x, y)
	local unit, failure = SentientSystems_FindUnit(playerID, unitID)

	if failure ~= nil then
		return failure
	end

	failure = GetMoveFailure(playerID, unit, x, y)

	if failure ~= nil then
		return failure
	end

	local parameters = SentientSystems_GetTileParams(UnitOperationTypes, x, y)

	parameters[UnitOperationTypes.PARAM_MODIFIERS] = UnitOperationMoveModifiers.MOVE_IGNORE_UNEXPLORED_DESTINATION

	return SentientSystems_RequestUnitOperation(unit, UnitOperationTypes.MOVE_TO, parameters, "The game won't start that move.")
end

-- Moves the unit to x, y by the game's own path, over as many turns as it
-- takes, and returns the result as JSON. It never attacks: a tile with an enemy
-- unit has no route. A result of ok means the game took the request, not that
-- the unit has arrived.
function SentientSystems_MoveUnit(playerID, unitID, x, y)
	return SentientSystems_RunAction("MoveUnit", MoveUnit, playerID, unitID, x, y)
end

-- Cancels the unit's queued move when no path reaches its destination any
-- more, and returns the destination's x and y, or nil. A path through
-- unrevealed tiles can end in one that blocks it, and the game keeps that move,
-- so the unit stands still without needing orders. See
-- docs/findings/actions/move-routes.md.
local function CancelDeadMove(unit)
	local destination = UnitManager.GetQueuedDestination(unit)

	if destination == nil or destination < 0 or HasRoute(unit, destination) then
		return nil
	end

	UnitManager.RequestCommand(unit, UnitCommandTypes.CANCEL)

	local plot = Map.GetPlotByIndex(destination)

	return plot:GetX(), plot:GetY()
end

-- Cancels the move of the player's unit when no path reaches its destination,
-- and keeps an event that says so. The UI script calls it when a move ends.
function SentientSystems_CancelDeadMove(playerID, unitID)
	local unit = UnitManager.GetUnit(playerID, unitID)
	local x, y = nil, nil

	if unit ~= nil then
		x, y = CancelDeadMove(unit)
	end

	if x ~= nil then
		SentientSystems_NoteMoveCancelled(playerID, unit, x, y)
	end
end

-- Does the same for each of the player's units. The UI script calls it when
-- the player's turn starts, since another unit can reveal a tile that blocks
-- the way.
function SentientSystems_CancelDeadMoves(playerID)
	for _, unit in Players[playerID]:GetUnits():Members() do
		SentientSystems_CancelDeadMove(playerID, unit:GetID())
	end
end

-- The unit actions, by name. Each function takes the player ID, the unit, x, y,
-- and type, and returns nil when it worked, and the reason it failed otherwise.
-- The order files add theirs below.
local ACTIONS = {}

function SentientSystems_AddUnitAction(name, action)
	ACTIONS[name] = action
end

-- Returns whether the kind of unit in the row can pillage and plunder: it has
-- strength and isn't an air unit. See docs/findings/actions/trade.md.
function SentientSystems_CanPillage(row)
	return row.Combat > 0 and row.Domain ~= "DOMAIN_AIR"
end

SentientSystems_Include("SentientSystemsCore_ActionsUnitStances")
SentientSystems_Include("SentientSystemsCore_ActionsUnitTiles")
SentientSystems_Include("SentientSystemsCore_ActionsUnitJobs")
SentientSystems_Include("SentientSystemsCore_ActionsUnitProduction")
SentientSystems_Include("SentientSystemsCore_ActionsUnitUpgrade")
SentientSystems_Include("SentientSystemsCore_ActionsUnitGreatPeople")
SentientSystems_Include("SentientSystemsCore_ActionsUnitReligion")
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

local function UnitAction(playerID, unitID, action, x, y, type)
	local unit, failure = SentientSystems_FindUnit(playerID, unitID)

	if failure ~= nil then
		return failure
	end

	if ACTIONS[action] == nil then
		return "Unknown unit action " .. tostring(action) .. ". The actions are " .. GetActionNames() .. "."
	end

	return ACTIONS[action](playerID, unit, x, y, type)
end

-- Gives a unit an order and returns the result as JSON. type is the promotion
-- to take for promote, the improvement to build for improve, and the route to
-- build for build_road. x and y are for the actions that name a tile.
function SentientSystems_UnitAction(playerID, unitID, action, x, y, type)
	return SentientSystems_RunAction("UnitAction", UnitAction, playerID, unitID, action, x, y, type)
end
