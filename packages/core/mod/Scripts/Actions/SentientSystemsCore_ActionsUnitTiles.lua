-- The unit orders that act on the unit's own tile: found city, improve, and
-- pillage, of an improvement or a road. Uses the stances file's helpers. The
-- calls are in docs/findings/actions/.

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
local function GetFoundCityHint(unit)
	local playerID = unit:GetOwner()
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
-- explains it. The game gives no reasons for the check. The tile has an
-- improvement, a road, or both to pillage.
local function GetPillageHint(unit)
	local playerID = unit:GetOwner()
	local plot = Map.GetPlot(unit:GetX(), unit:GetY())
	local improvement = plot:GetImprovementType() ~= -1
	local road = plot:GetRouteType() ~= -1

	if unit:GetMovesRemaining() <= 0 then
		return "The unit has no moves left."
	end

	-- A unit with an ability for it pillages for less, which the game's check
	-- allows, so this only explains a refusal.
	if unit:GetMovesRemaining() < GlobalParameters.PILLAGE_MOVEMENT_COST then
		return "Pillaging takes " .. GlobalParameters.PILLAGE_MOVEMENT_COST .. " moves, and the unit has " .. unit:GetMovesRemaining() .. "."
	end

	if not improvement and not road then
		return "There is no improvement or road on the tile."
	end

	if (not improvement or plot:IsImprovementPillaged()) and (not road or plot:IsRoutePillaged()) then
		return "Nothing on the tile is left to pillage."
	end

	if plot:GetOwner() == playerID then
		return "The tile is yours."
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

-- Whether a kind of unit has build charges, which makes it a builder. The job
-- orders use this too.
function SentientSystems_IsBuilder(row)
	return row.BuildCharges > 0
end

local function GetImproveFailure(unit, improvementType, improvements)
	return SentientSystems_GetOrderFailure(unit, "improve", SentientSystems_IsBuilder(GameInfo.Units[unit:GetUnitType()]), function()
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

SentientSystems_AddUnitAction("found_city", function(_, unit)
	return SentientSystems_DoOperation(unit, "found_city", "UNITOPERATION_FOUND_CITY", {
		kind = function(row)
			return row.FoundCity
		end,
		hint = GetFoundCityHint,
	})
end)

-- Pillage takes the tile's improvement or district, and when the game won't
-- but a road is there to take, it pillages the road. UnitPanel.lua lists them
-- as two orders, "Pillage" and "Pillage Road". A tile with both takes two
-- orders, the improvement first.
SentientSystems_AddUnitAction("pillage", function(_, unit)
	local options = {
		kind = SentientSystems_CanPillage,
		hint = GetPillageHint,
	}
	local failure = SentientSystems_DoOperation(unit, "pillage", "UNITOPERATION_PILLAGE", options)

	if failure == nil then
		return nil
	end

	local road = GameInfo.UnitOperations["UNITOPERATION_PILLAGE_ROUTE"].Hash

	if options.kind(GameInfo.Units[unit:GetUnitType()]) and UnitManager.CanStartOperation(unit, road, nil, false, OperationResultsTypes.NO_TARGETS) then
		UnitManager.RequestOperation(unit, road)

		return nil
	end

	return failure
end)

SentientSystems_AddUnitAction("improve", function(_, unit, _, _, type)
	return Improve(unit, type)
end)
