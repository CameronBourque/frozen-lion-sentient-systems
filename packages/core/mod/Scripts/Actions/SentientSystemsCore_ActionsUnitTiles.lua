-- The unit orders that act on the unit's own tile: found city, improve, and
-- pillage. SentientSystemsCore_ActionsUnits.lua loads this file, after the
-- stances file, whose helpers it uses. The calls are in
-- docs/findings/game-actions.md.

-- Returns whether the player has revealed the tile. A city on a revealed tile
-- shows its banner, so the player knows it.
local function KnowsTile(playerID, x, y)
	return PlayersVisibility[playerID]:IsRevealed(x, y)
end

-- Returns the name of a city within the game's minimum range of the tile that
-- the player knows, or nil. A city can't be founded that close to another.
local function FindCityInRange(playerID, x, y)
	for _, player in ipairs(PlayerManager.GetAlive()) do
		for _, city in player:GetCities():Members() do
			local near = Map.GetPlotDistance(x, y, city:GetX(), city:GetY()) <= GlobalParameters.CITY_MIN_RANGE

			if near and KnowsTile(playerID, city:GetX(), city:GetY()) then
				return Locale.Lookup(city:GetName())
			end
		end
	end

	return nil
end

-- Returns why the settler can't found a city on its tile, or nil when nothing
-- here explains it. The game gives no reasons for the check.
local function GetFoundCityHint(playerID, unit)
	local plot = Map.GetPlot(unit:GetX(), unit:GetY())
	local owner = plot:GetOwner()

	if unit:GetMovesRemaining() <= 0 then
		return "The unit has no moves left."
	end

	if plot:IsWater() or plot:IsImpassable() then
		return "A city can't be founded on water or an impassable tile."
	end

	if owner ~= -1 and owner ~= playerID then
		return "Another player owns the tile."
	end

	local city = FindCityInRange(playerID, unit:GetX(), unit:GetY())

	if city ~= nil then
		return "The tile is within " .. GlobalParameters.CITY_MIN_RANGE .. " tiles of " .. city .. "."
	end

	return nil
end

-- Returns why the unit can't pillage its tile, or nil when nothing here
-- explains it. The game gives no reasons for the check.
local function GetPillageHint(playerID, unit)
	local plot = Map.GetPlot(unit:GetX(), unit:GetY())

	if unit:GetMovesRemaining() <= 0 then
		return "The unit has no moves left."
	end

	if plot:GetImprovementType() == -1 then
		return "There is no improvement on the tile."
	end

	if plot:IsImprovementPillaged() then
		return "The improvement is already pillaged."
	end

	if plot:GetOwner() == playerID then
		return "The improvement is yours."
	end

	return nil
end

-- Returns the improvements the unit can build on its tile now, each with its
-- index and type. The panel lists the improvements of one check and then checks
-- each one for real.
local function GetImprovements(unit, parameters)
	local canEver, results = UnitManager.CanStartOperation(unit, UnitOperationTypes.BUILD_IMPROVEMENT, nil, parameters, true)
	local improvements = {}

	for _, index in ipairs(canEver and results and results[UnitOperationResults.IMPROVEMENTS] or {}) do
		parameters[UnitOperationTypes.PARAM_IMPROVEMENT_TYPE] = index

		if UnitManager.CanStartOperation(unit, UnitOperationTypes.BUILD_IMPROVEMENT, nil, parameters, true) then
			improvements[#improvements + 1] = { index = index, type = GameInfo.Improvements[index].ImprovementType }
		end
	end

	parameters[UnitOperationTypes.PARAM_IMPROVEMENT_TYPE] = nil

	return improvements
end

-- Whether a kind of unit has build charges, which makes it a builder.
local function IsBuilder(row)
	return row.BuildCharges > 0
end

-- Returns why the unit can't build the improvement, from what it can build.
local function GetImproveFailure(unit, improvementType, improvements)
	return SentientSystems_GetOrderFailure(unit, "improve", IsBuilder(GameInfo.Units[unit:GetUnitType()]), function()
		if unit:GetMovesRemaining() <= 0 then
			return "The unit has no moves left."
		end

		if unit:GetBuildCharges() <= 0 then
			return "The unit has no build charges left."
		end

		if #improvements == 0 then
			return "The unit can't build any improvement here."
		end

		local types = {}

		for i, improvement in ipairs(improvements) do
			types[i] = improvement.type
		end

		return "The unit can't build " .. tostring(improvementType) .. " here. It can build " .. table.concat(types, ", ") .. "."
	end)
end

-- Requests the improvement of that type on the unit's tile, or returns why the
-- unit can't build it.
local function Improve(unit, improvementType)
	local parameters = { [UnitOperationTypes.PARAM_X] = unit:GetX(), [UnitOperationTypes.PARAM_Y] = unit:GetY() }
	local improvements = GetImprovements(unit, parameters)

	for _, improvement in ipairs(improvements) do
		if improvement.type == improvementType then
			parameters[UnitOperationTypes.PARAM_IMPROVEMENT_TYPE] = GameInfo.Improvements[improvement.index].Hash
			UnitManager.RequestOperation(unit, UnitOperationTypes.BUILD_IMPROVEMENT, parameters)

			return nil
		end
	end

	return GetImproveFailure(unit, improvementType, improvements)
end

SentientSystems_AddUnitAction("found_city", function(playerID, unit)
	return SentientSystems_DoOperation(unit, "found_city", "UNITOPERATION_FOUND_CITY", {
		kind = function(row)
			return row.FoundCity
		end,
		hint = function()
			return GetFoundCityHint(playerID, unit)
		end,
	})
end)

SentientSystems_AddUnitAction("pillage", function(playerID, unit)
	return SentientSystems_DoOperation(unit, "pillage", "UNITOPERATION_PILLAGE", {
		kind = function(row)
			return row.Combat > 0 and row.Domain ~= "DOMAIN_AIR"
		end,
		hint = function()
			return GetPillageHint(playerID, unit)
		end,
	})
end)

SentientSystems_AddUnitAction("improve", function(_, unit, _, _, type)
	return Improve(unit, type)
end)
