-- The air movement orders: rebase, deploy, airlift, and paradrop. The units
-- file loads this file. The calls are in docs/findings/actions/.

-- The most tiles a reason lists before it gives a count.
local MAX_LISTED = 8

-- Returns whether the unit's kind has the paradrop ability, which the type
-- tags give.
local function CanParadrop(unit)
	local unitType = GameInfo.Units[unit:GetUnitType()].UnitType

	for row in GameInfo.TypeTags() do
		if row.Type == unitType and row.Tag == "CLASS_PARADROP" then
			return true
		end
	end

	return false
end

local function IsAirUnit(unit)
	return GameInfo.Units[unit:GetUnitType()].Domain == "DOMAIN_AIR"
end

-- A ship next to an aerodrome gets no airlift tile.
local function IsNotShip(unit)
	return GameInfo.Units[unit:GetUnitType()].Domain ~= "DOMAIN_SEA"
end

-- The orders by action name. A rebase and a deploy are unit operations, and an
-- airlift and a paradrop are unit commands. kind says whether the unit could
-- ever do it, moves whether it needs moves left, and none is the reason when
-- the game lists no tile.
local ORDERS = {
	rebase = { operation = "REBASE", kind = IsAirUnit, moves = true, none = "The unit has no tile in range to rebase to." },
	deploy = { operation = "DEPLOY", kind = IsAirUnit, none = "The unit has no tile in range to deploy to." },
	airlift = {
		command = "AIRLIFT",
		kind = IsNotShip,
		moves = true,
		none = "An airlift needs the unit on or next to a city or aerodrome with an airport, and another to land in.",
	},
	paradrop = {
		command = "PARADROP",
		kind = CanParadrop,
		moves = true,
		none = "The unit has to start in a city or on an airstrip to paradrop.",
	},
}

-- Returns the tiles the game lists for the order, each as x and y.
local function GetTiles(unit, order)
	local indexes

	if order.operation ~= nil then
		local targets = UnitManager.GetOperationTargets(unit, UnitOperationTypes[order.operation])

		indexes = targets and targets[UnitOperationResults.PLOTS] or {}
	else
		local targets = UnitManager.GetCommandTargets(unit, UnitCommandTypes[order.command])

		indexes = targets and targets[UnitCommandResults.PLOTS] or {}
	end

	local tiles = {}

	for i, index in ipairs(indexes) do
		local plot = Map.GetPlotByIndex(index)

		tiles[i] = { x = plot:GetX(), y = plot:GetY() }
	end

	return tiles
end

-- Requests the order for x, y, and returns whether the game started it. The UI
-- checks the order with the tile, and a command takes it as the third argument.
local function Start(unit, order, x, y)
	if order.operation ~= nil then
		local parameters = { [UnitOperationTypes.PARAM_X] = x, [UnitOperationTypes.PARAM_Y] = y }
		local hash = UnitOperationTypes[order.operation]

		if not UnitManager.CanStartOperation(unit, hash, nil, parameters) then
			return false
		end

		UnitManager.RequestOperation(unit, hash, parameters)

		return true
	end

	local parameters = { [UnitCommandTypes.PARAM_X] = x, [UnitCommandTypes.PARAM_Y] = y }
	local command = UnitCommandTypes[order.command]

	if not UnitManager.CanStartCommand(unit, command, parameters) then
		return false
	end

	UnitManager.RequestCommand(unit, command, parameters)

	return true
end

-- Returns why the tile isn't one the unit can go to, with the nearest tiles
-- that are.
local function GetNotListedReason(unit, action, tiles)
	local ux, uy = unit:GetX(), unit:GetY()

	table.sort(tiles, function(a, b)
		return Map.GetPlotDistance(ux, uy, a.x, a.y) < Map.GetPlotDistance(ux, uy, b.x, b.y)
	end)

	local listed = {}

	for i = 1, math.min(#tiles, MAX_LISTED) do
		listed[i] = "(" .. tiles[i].x .. ", " .. tiles[i].y .. ")"
	end

	local more = #tiles > MAX_LISTED and ", and " .. (#tiles - MAX_LISTED) .. " more" or ""

	return "That tile isn't one the unit can " .. action .. " to. The nearest that are " .. table.concat(listed, ", ") .. more .. "."
end

-- Requests the order for x, y, or returns why it can't start. The game gives no
-- reasons, so the kind, the moves, and the listed tiles are checked in turn.
local function Run(unit, action, order, x, y)
	if not Map.IsPlot(x, y) then
		return "The tile (" .. tostring(x) .. ", " .. tostring(y) .. ") is off the map."
	end

	if order.kind ~= nil and not order.kind(unit) then
		return "This kind of unit can't " .. action .. "."
	end

	if order.moves and unit:GetMovesRemaining() <= 0 then
		return "The unit has no moves left."
	end

	local tiles = GetTiles(unit, order)

	if #tiles == 0 then
		return order.none
	end

	for _, tile in ipairs(tiles) do
		if tile.x == x and tile.y == y then
			if Start(unit, order, x, y) then
				return nil
			end

			return "The game won't start that " .. action .. "."
		end
	end

	return GetNotListedReason(unit, action, tiles)
end

for action, order in pairs(ORDERS) do
	SentientSystems_AddUnitAction(action, function(_, unit, x, y)
		return Run(unit, action, order, x, y)
	end)
end
