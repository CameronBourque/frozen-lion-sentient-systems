-- The runner for the orders that name a tile. The units file loads it first,
-- and each order file passes its orders to SentientSystems_AddTileOrders. The
-- calls are in docs/findings/actions/.

-- Returns the tiles the game lists for the order, each as x and y. An order
-- with marked set lists only the tiles the game marks as a target, as the UI's
-- range display does.
local function GetTiles(unit, order)
	local targets, indexes

	if order.operation ~= nil then
		targets = UnitManager.GetOperationTargets(unit, UnitOperationTypes[order.operation])
		indexes = targets and targets[UnitOperationResults.PLOTS] or {}
	else
		targets = UnitManager.GetCommandTargets(unit, UnitCommandTypes[order.command])
		indexes = targets and targets[UnitCommandResults.PLOTS] or {}
	end

	local tiles = {}

	for i, index in ipairs(indexes) do
		if not order.marked or targets[CityCommandResults.MODIFIERS][i] == CityCommandResults.MODIFIER_IS_TARGET then
			local plot = Map.GetPlotByIndex(index)

			tiles[#tiles + 1] = { x = plot:GetX(), y = plot:GetY() }
		end
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

-- Returns why the tile isn't one the order can take, with the nearest tiles
-- that are.
local function GetNotListedReason(unit, order, tiles)
	local ux, uy = unit:GetX(), unit:GetY()

	table.sort(tiles, function(a, b)
		return Map.GetPlotDistance(ux, uy, a.x, a.y) < Map.GetPlotDistance(ux, uy, b.x, b.y)
	end)

	return "That tile isn't one the unit can " .. order.verb .. " " .. order.prep .. ". The nearest that are " .. SentientSystems_ListTiles(tiles) .. "."
end

-- Requests the order for x, y, or returns why it can't start. The game gives no
-- reasons, so the kind, the moves, and the listed tiles are checked in turn.
local function Run(unit, order, x, y)
	if not Map.IsPlot(x, y) then
		return "The tile (" .. tostring(x) .. ", " .. tostring(y) .. ") is off the map."
	end

	if order.kind ~= nil and not order.kind(unit) then
		return "This kind of unit can't " .. order.verb .. "."
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

			return "The game won't start that " .. order.noun .. "."
		end
	end

	return GetNotListedReason(unit, order, tiles)
end

-- Registers the orders, by action name. Each is a unit operation (operation) or
-- a unit command (command), and its fields finish the reasons: verb, prep, and
-- noun say what the unit does, kind says whether the unit could ever do it,
-- moves whether it needs moves left, and none is the reason when the game lists
-- no tile.
function SentientSystems_AddTileOrders(orders)
	for action, order in pairs(orders) do
		SentientSystems_AddUnitAction(action, function(_, unit, x, y)
			return Run(unit, order, x, y)
		end)
	end
end
