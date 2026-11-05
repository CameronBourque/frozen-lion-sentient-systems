-- The builder jobs on the unit's tile that need no choice. The units file loads
-- this file, and it uses SentientSystems_IsBuilder from the tiles file. The
-- calls are in docs/findings/actions/.

local function GetPlot(unit)
	return Map.GetPlot(unit:GetX(), unit:GetY())
end

-- Whether a kind of unit builds routes. In the game only the Military
-- Engineer does, and a builder never gets the order.
local function BuildsRoutes(row)
	for route in GameInfo.Route_ValidBuildUnits() do
		if route.UnitType == row.UnitType then
			return true
		end
	end

	return false
end

local function HasTech(playerID, techType)
	return Players[playerID]:GetTechs():HasTech(GameInfo.Technologies[techType].Index)
end

local function GetTechName(techType)
	return Locale.Lookup(GameInfo.Technologies[techType].Name)
end

-- Returns the row of the resource's harvest, or nil when it can't be harvested.
local function FindHarvest(resourceType)
	for row in GameInfo.Resource_Harvests() do
		if row.ResourceType == resourceType then
			return row
		end
	end

	return nil
end

-- Returns the reasons the game gives for the operation, joined, or nil. Most of
-- these jobs give none, but a repair gives one for a drought.
local function GetGameReasons(unit, hash)
	local _, results = UnitManager.CanStartOperation(unit, hash, nil, false, OperationResultsTypes.ALL)
	local reasons = results and results[UnitOperationResults.FAILURE_REASONS]

	if reasons == nil or #reasons == 0 then
		return nil
	end

	local texts = {}

	for i, reason in ipairs(reasons) do
		texts[i] = Locale.Lookup(reason)
	end

	return table.concat(texts, " ")
end

-- Returns why the unit can't start a job at all, or nil. Removing a feature and
-- harvesting use a build charge, and the other jobs don't.
local function GetUnitHint(unit, usesCharge)
	if unit:GetMovesRemaining() <= 0 then
		return "The unit has no moves left."
	end

	if usesCharge and unit:GetBuildCharges() <= 0 then
		return "The unit has no build charges left."
	end

	return nil
end

-- Returns why the unit can't build a road on its tile, or nil. The game builds
-- the best route the player has, and a tile that has it needs no more.
local function GetBuildRoadHint(unit)
	local plot = GetPlot(unit)
	local reason = GetUnitHint(unit, false)

	if reason ~= nil then
		return reason
	end

	if plot:IsWater() then
		return "A road can't be built on water."
	end

	local route = plot:GetRouteType()

	if route ~= -1 and not plot:IsRoutePillaged() then
		return "The tile has " .. Locale.Lookup(GameInfo.Routes[route].Name) .. ", and the unit can't build a better route."
	end

	return nil
end

-- Returns why the unit can't remove the feature on its tile, or nil. A feature
-- needs a tech, an empty tile, and a tile in the player's borders.
local function GetRemoveFeatureHint(playerID, unit)
	local plot = GetPlot(unit)
	local reason = GetUnitHint(unit, true)

	if reason ~= nil then
		return reason
	end

	local feature = plot:GetFeatureType()

	if feature == -1 then
		return "There is no feature on the tile."
	end

	local row = GameInfo.Features[feature]
	local name = Locale.Lookup(row.Name)

	if not row.Removable then
		return name .. " can't be removed."
	end

	if row.RemoveTech ~= nil and not HasTech(playerID, row.RemoveTech) then
		return "Removing " .. name .. " needs " .. GetTechName(row.RemoveTech) .. "."
	end

	if plot:GetImprovementType() ~= -1 then
		return "Remove the improvement first."
	end

	if plot:GetOwner() == -1 then
		return "The tile is outside your borders."
	end

	if plot:GetOwner() ~= playerID then
		return "Another player owns the tile."
	end

	return nil
end

-- Returns why the unit can't harvest the resource on its tile, or nil. A
-- resource the player can't see yet doesn't count.
local function GetHarvestHint(playerID, unit)
	local plot = GetPlot(unit)
	local reason = GetUnitHint(unit, true)

	if reason ~= nil then
		return reason
	end

	local row = GameInfo.Resources[plot:GetResourceType()]

	if row == nil or not Players[playerID]:GetResources():IsResourceVisible(plot:GetResourceTypeHash()) then
		return "There is no resource on the tile."
	end

	local name = Locale.Lookup(row.Name)
	local harvest = FindHarvest(row.ResourceType)

	if harvest == nil then
		return name .. " can't be harvested."
	end

	if harvest.PrereqTech ~= nil and not HasTech(playerID, harvest.PrereqTech) then
		return "Harvesting " .. name .. " needs " .. GetTechName(harvest.PrereqTech) .. "."
	end

	if plot:GetImprovementType() ~= -1 then
		return "Remove the improvement first."
	end

	return nil
end

local function GetRemoveImprovementHint(unit)
	local reason = GetUnitHint(unit, false)

	if reason ~= nil then
		return reason
	end

	if GetPlot(unit):GetImprovementType() == -1 then
		return "There is no improvement on the tile."
	end

	return nil
end

-- Returns the operation that repairs the unit's tile: the improvement's when it
-- is pillaged, and the route's otherwise.
local function GetRepairOperation(unit)
	local plot = GetPlot(unit)
	local improvement = plot:GetImprovementType() ~= -1 and plot:IsImprovementPillaged()

	if not improvement and plot:IsRoutePillaged() then
		return "UNITOPERATION_REPAIR_ROUTE"
	end

	return "UNITOPERATION_REPAIR"
end

-- Returns why the unit can't repair its tile, or nil. The game gives a reason
-- of its own for a drought.
local function GetRepairHint(unit, operation)
	local plot = GetPlot(unit)
	local reason = GetUnitHint(unit, false)

	if reason ~= nil then
		return reason
	end

	local pillaged = plot:IsRoutePillaged() or (plot:GetImprovementType() ~= -1 and plot:IsImprovementPillaged())

	if not pillaged then
		return "Nothing on the tile is pillaged."
	end

	return GetGameReasons(unit, GameInfo.UnitOperations[operation].Hash)
end

SentientSystems_AddUnitAction("build_road", function(_, unit, _, _, type)
	local operation = GameInfo.UnitOperations["UNITOPERATION_BUILD_ROUTE"]

	if type ~= nil then
		local _, results = UnitManager.CanStartOperation(unit, operation.Hash, nil, false, OperationResultsTypes.ALL)
		local route = results and results[UnitOperationResults.ROUTE_TYPE]

		if route ~= nil and route ~= type then
			return "The unit would build " .. route .. ", not " .. tostring(type) .. "."
		end
	end

	return SentientSystems_DoOperation(unit, "build_road", "UNITOPERATION_BUILD_ROUTE", {
		kind = BuildsRoutes,
		hint = function()
			return GetBuildRoadHint(unit)
		end,
	})
end)

SentientSystems_AddUnitAction("remove_feature", function(playerID, unit)
	return SentientSystems_DoOperation(unit, "remove_feature", "UNITOPERATION_REMOVE_FEATURE", {
		kind = SentientSystems_IsBuilder,
		hint = function()
			return GetRemoveFeatureHint(playerID, unit)
		end,
	})
end)

SentientSystems_AddUnitAction("harvest", function(playerID, unit)
	return SentientSystems_DoOperation(unit, "harvest", "UNITOPERATION_HARVEST_RESOURCE", {
		kind = SentientSystems_IsBuilder,
		hint = function()
			return GetHarvestHint(playerID, unit)
		end,
	})
end)

SentientSystems_AddUnitAction("repair", function(_, unit)
	local operation = GetRepairOperation(unit)

	return SentientSystems_DoOperation(unit, "repair", operation, {
		kind = SentientSystems_IsBuilder,
		hint = function()
			return GetRepairHint(unit, operation)
		end,
	})
end)

SentientSystems_AddUnitAction("remove_improvement", function(_, unit)
	return SentientSystems_DoOperation(unit, "remove_improvement", "UNITOPERATION_REMOVE_IMPROVEMENT", {
		kind = SentientSystems_IsBuilder,
		hint = function()
			return GetRemoveImprovementHint(unit)
		end,
	})
end)
