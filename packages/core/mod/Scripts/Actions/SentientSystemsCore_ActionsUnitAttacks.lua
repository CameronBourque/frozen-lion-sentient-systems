-- The attack orders, with a ship's coastal raid. The units file loads this
-- file. The calls are in docs/findings/actions/.

-- The most targets a reason lists before it gives a count.
local MAX_LISTED = 8

-- Returns the tiles the operation can hit, which the UI's attack range marks as
-- targets, each as x and y.
function SentientSystems_GetTargetTiles(results, plots, modifiers, isTarget)
	local tiles = {}

	for i, index in ipairs(results and results[plots] or {}) do
		if results[modifiers][i] == isTarget then
			local plot = Map.GetPlotByIndex(index)

			tiles[#tiles + 1] = { x = plot:GetX(), y = plot:GetY() }
		end
	end

	return tiles
end

-- Returns the reason a tile isn't a target, with the tiles that are.
function SentientSystems_GetNotTargetReason(tiles)
	if #tiles == 0 then
		return "That tile isn't a target, and nothing is in range."
	end

	local listed = {}

	for i = 1, math.min(#tiles, MAX_LISTED) do
		listed[i] = "(" .. tiles[i].x .. ", " .. tiles[i].y .. ")"
	end

	local more = #tiles > MAX_LISTED and ", and " .. (#tiles - MAX_LISTED) .. " more" or ""

	return "That tile isn't a target. The targets in range are " .. table.concat(listed, ", ") .. more .. "."
end

-- Returns whether the tile holds a unit that the player sees or a city that
-- another player owns. Only a tile the player sees is asked.
local function HasEnemy(playerID, x, y)
	for _, other in ipairs(Units.GetUnitsInPlot(Map.GetPlot(x, y))) do
		if other:GetOwner() ~= playerID and PlayersVisibility[playerID]:IsUnitVisible(other) then
			return true
		end
	end

	local city = CityManager.GetCityAt(x, y)

	return city ~= nil and city:GetOwner() ~= playerID
end

-- Returns how the unit attacks, as the UI picks: air units fly at a tile, a
-- unit that is stronger at range or bombard shoots, and the rest fight in melee
-- by moving into the tile. A unit with no strength can't attack.
local function GetAttackKind(unit)
	local melee, ranged, bombard = unit:GetCombat(), unit:GetRangedCombat(), unit:GetBombardCombat()

	if melee <= 0 and ranged <= 0 and bombard <= 0 then
		return nil
	end

	if GameInfo.Units[unit:GetUnitType()].Domain == "DOMAIN_AIR" then
		return "air"
	end

	if ranged > melee or bombard > melee then
		return "ranged"
	end

	return "melee"
end

local function GetAttackFailure(playerID, unit, x, y)
	if x == nil or y == nil then
		return "An attack needs the tile to hit."
	end

	if not Map.IsPlot(x, y) then
		return "The tile (" .. x .. ", " .. y .. ") is off the map."
	end

	if not PlayersVisibility[playerID]:IsVisible(x, y) then
		return "You can't see that tile."
	end

	if unit:GetAttacksRemaining() <= 0 then
		return "The unit has no attacks left."
	end

	return SentientSystems_GetWarFailure(playerID, unit, x, y, "Attacking")
end

-- Requests a melee attack on an adjacent tile, or returns why it can't.
local function MeleeAttack(playerID, unit, x, y)
	local parameters = {
		[UnitOperationTypes.PARAM_X] = x,
		[UnitOperationTypes.PARAM_Y] = y,
		[UnitOperationTypes.PARAM_MODIFIERS] = UnitOperationMoveModifiers.ATTACK + UnitOperationMoveModifiers.MOVE_IGNORE_UNEXPLORED_DESTINATION,
	}

	if Map.GetPlotDistance(unit:GetX(), unit:GetY(), x, y) ~= 1 then
		return "A melee unit attacks an adjacent tile. Move next to it first."
	end

	if unit:GetMovesRemaining() <= 0 then
		return "The unit has no moves left."
	end

	if not HasEnemy(playerID, x, y) then
		return "There is nothing to attack on that tile."
	end

	if not UnitManager.CanStartOperation(unit, UnitOperationTypes.MOVE_TO, nil, parameters) then
		return "The game won't start that attack."
	end

	UnitManager.RequestOperation(unit, UnitOperationTypes.MOVE_TO, parameters)

	return nil
end

-- Requests a ranged or an air attack on a tile in range, or returns why it
-- can't. The UI's range display marks the tiles in range that hold a target.
local function RangedAttack(unit, operation, x, y)
	local R = UnitOperationResults
	local tiles = SentientSystems_GetTargetTiles(UnitManager.GetOperationTargets(unit, operation), R.PLOTS, R.MODIFIERS, R.MODIFIER_IS_TARGET)
	local parameters = { [UnitOperationTypes.PARAM_X] = x, [UnitOperationTypes.PARAM_Y] = y }

	for _, tile in ipairs(tiles) do
		if tile.x == x and tile.y == y then
			if not UnitManager.CanStartOperation(unit, operation, nil, parameters) then
				return "The game won't start that attack."
			end

			UnitManager.RequestOperation(unit, operation, parameters)

			return nil
		end
	end

	return SentientSystems_GetNotTargetReason(tiles)
end

-- Returns the land tiles a ship can hit with a coastal raid. The UI marks all
-- of the operation's plots, with no target flag. Other units have none. See
-- OnInterfaceModeChange_CoastalRaid in WorldInput.lua.
local function GetRaidTiles(unit)
	local tiles = {}

	if GameInfo.Units[unit:GetUnitType()].Domain ~= "DOMAIN_SEA" then
		return tiles
	end

	local results = UnitManager.GetOperationTargets(unit, UnitOperationTypes.COASTAL_RAID)

	for _, index in ipairs(results and results[UnitOperationResults.PLOTS] or {}) do
		local plot = Map.GetPlotByIndex(index)

		tiles[#tiles + 1] = { x = plot:GetX(), y = plot:GetY() }
	end

	return tiles
end

local function IsRaidTile(tiles, x, y)
	for _, tile in ipairs(tiles) do
		if tile.x == x and tile.y == y then
			return true
		end
	end

	return false
end

-- Requests a coastal raid on a tile of the raid list, or returns why it can't.
local function Raid(unit, x, y)
	local parameters = { [UnitOperationTypes.PARAM_X] = x, [UnitOperationTypes.PARAM_Y] = y }

	if not UnitManager.CanStartOperation(unit, UnitOperationTypes.COASTAL_RAID, nil, parameters) then
		return "The game won't start that raid."
	end

	UnitManager.RequestOperation(unit, UnitOperationTypes.COASTAL_RAID, parameters)

	return nil
end

-- Returns how a refusal ends: the tiles a ship could raid instead.
local function ListRaidTiles(tiles)
	local listed = {}

	for i = 1, math.min(#tiles, MAX_LISTED) do
		listed[i] = "(" .. tiles[i].x .. ", " .. tiles[i].y .. ")"
	end

	return " A coastal raid can hit " .. table.concat(listed, ", ") .. (#tiles > MAX_LISTED and ", and " .. (#tiles - MAX_LISTED) .. " more" or "") .. "."
end

-- The UI tries a ranged attack, then a coastal raid, and then a move that
-- attacks, so a ship's attack on a land tile is a raid when the tile is one.
SentientSystems_AddUnitAction("attack", function(playerID, unit, x, y)
	local kind = GetAttackKind(unit)

	if kind == nil then
		return "This kind of unit can't attack."
	end

	local failure = GetAttackFailure(playerID, unit, x, y)

	if failure ~= nil then
		return failure
	end

	local raid = GetRaidTiles(unit)

	if kind == "melee" and IsRaidTile(raid, x, y) then
		return Raid(unit, x, y)
	end

	if kind == "melee" then
		failure = MeleeAttack(playerID, unit, x, y)
	else
		failure = RangedAttack(unit, kind == "air" and UnitOperationTypes.AIR_ATTACK or UnitOperationTypes.RANGE_ATTACK, x, y)
	end

	if failure ~= nil and IsRaidTile(raid, x, y) then
		return Raid(unit, x, y)
	end

	if failure ~= nil and #raid > 0 then
		return failure .. ListRaidTiles(raid)
	end

	return failure
end)

-- A priority target hits the support or civilian unit that a military unit
-- escorts on a tile, instead of the military unit. The game marks the tiles
-- that have one. Spec ops and air units have it.
SentientSystems_AddTileOrders({
	priority_target = {
		command = "PRIORITY_TARGET",
		verb = "pick a priority target",
		noun = "priority target",
		prep = "on",
		moves = true,
		marked = true,
		none = "No tile in range has a unit to pick out. Only some units, such as spec ops and air units, can pick a priority target.",
	},
})
