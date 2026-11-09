-- The attack orders, with a ship's coastal raid. The units file loads this
-- file. The calls are in docs/findings/actions/.

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

-- Returns nil when x, y is one of the target tiles, and the reason it isn't,
-- with the tiles that are, otherwise.
function SentientSystems_GetTargetFailure(tiles, x, y)
	if SentientSystems_HasTile(tiles, x, y) then
		return nil
	end

	if #tiles == 0 then
		return "That tile isn't a target, and nothing is in range."
	end

	return "That tile isn't a target. The targets in range are " .. SentientSystems_ListTiles(tiles) .. "."
end

-- Returns whether the tile holds a unit that the player sees or a city that
-- another player owns. Only a tile the player sees is asked. GetUnitsInPlot
-- leaves out the units of the religious, trade, and spy layers, so this asks
-- every layer, as UnitFlagManager.lua and WorldInput.lua do.
local function HasEnemy(playerID, x, y)
	for _, other in ipairs(Units.GetUnitsInPlotLayerID(x, y, MapLayers.ANY)) do
		if other:GetOwner() ~= playerID and PlayersVisibility[playerID]:IsUnitVisible(other) then
			return true
		end
	end

	local city = CityManager.GetCityAt(x, y)

	return city ~= nil and city:GetOwner() ~= playerID
end

-- Returns how the unit attacks, as the UI picks: air units fly at a tile, a
-- unit that is stronger at range or bombard shoots, and the rest fight in melee
-- by moving into the tile. A religious unit has no combat strength and fights
-- in melee with its religious strength, at peace or at war. A unit with
-- neither can't attack.
local function GetAttackKind(unit)
	local melee, ranged, bombard = unit:GetCombat(), unit:GetRangedCombat(), unit:GetBombardCombat()

	if melee <= 0 and ranged <= 0 and bombard <= 0 then
		return unit:GetReligiousStrength() > 0 and "melee" or nil
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

	local unseen = SentientSystems_GetUnseenTileFailure(playerID, x, y)

	if unseen ~= nil then
		return unseen
	end

	if unit:GetAttacksRemaining() <= 0 then
		return "The unit has no attacks left."
	end

	return SentientSystems_GetWarFailure(playerID, unit, x, y, "Attacking")
end

-- Requests a melee attack on an adjacent tile, or returns why it can't.
local function MeleeAttack(playerID, unit, x, y)
	local parameters = SentientSystems_GetTileParams(UnitOperationTypes, x, y)

	parameters[UnitOperationTypes.PARAM_MODIFIERS] = UnitOperationMoveModifiers.ATTACK + UnitOperationMoveModifiers.MOVE_IGNORE_UNEXPLORED_DESTINATION

	if Map.GetPlotDistance(unit:GetX(), unit:GetY(), x, y) ~= 1 then
		return "A melee unit attacks an adjacent tile. Move next to it first."
	end

	if unit:GetMovesRemaining() <= 0 then
		return "The unit has no moves left."
	end

	if not HasEnemy(playerID, x, y) then
		return "There is nothing to attack on that tile."
	end

	return SentientSystems_RequestUnitOperation(unit, UnitOperationTypes.MOVE_TO, parameters, "The game won't start that attack.")
end

-- Requests a ranged or an air attack on a tile in range, or returns why it
-- can't. The UI's range display marks the tiles in range that hold a target.
local function RangedAttack(unit, operation, x, y)
	local R = UnitOperationResults
	local tiles = SentientSystems_GetTargetTiles(UnitManager.GetOperationTargets(unit, operation), R.PLOTS, R.MODIFIERS, R.MODIFIER_IS_TARGET)
	local failure = SentientSystems_GetTargetFailure(tiles, x, y)

	if failure ~= nil then
		return failure
	end

	return SentientSystems_RequestUnitOperation(unit, operation, SentientSystems_GetTileParams(UnitOperationTypes, x, y), "The game won't start that attack.")
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

-- Requests a coastal raid on a tile of the raid list, or returns why it can't.
local function Raid(unit, x, y)
	return SentientSystems_RequestUnitOperation(unit, UnitOperationTypes.COASTAL_RAID, SentientSystems_GetTileParams(UnitOperationTypes, x, y), "The game won't start that raid.")
end

-- Returns how a refusal ends: the tiles a ship could raid instead.
local function ListRaidTiles(tiles)
	return " A coastal raid can hit " .. SentientSystems_ListTiles(tiles) .. "."
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

	if kind == "melee" and SentientSystems_HasTile(raid, x, y) then
		return Raid(unit, x, y)
	end

	if kind == "melee" then
		failure = MeleeAttack(playerID, unit, x, y)
	else
		failure = RangedAttack(unit, kind == "air" and UnitOperationTypes.AIR_ATTACK or UnitOperationTypes.RANGE_ATTACK, x, y)
	end

	if failure ~= nil and SentientSystems_HasTile(raid, x, y) then
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
