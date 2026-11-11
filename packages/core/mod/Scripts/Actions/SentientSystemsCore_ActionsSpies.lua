-- The spy actions: a mission, a trip to another city, and an escape route.
-- Uses the lists of the spy missions choice and the escape screen's routes. The
-- calls are in docs/findings/actions/spies.md.

SentientSystems_Include("SentientSystemsCore_ChoicesSpyMissions")
SentientSystems_Include("SentientSystemsCore_Espionage")

-- Returns the player's spy, or the reason it can't act. A spy takes orders
-- only when it is ready to move and awake, as the chooser opens only then. See
-- GoToProperInterfaceMode in EspionageChooser.lua.
local function FindReadySpy(playerID, unitID)
	local spy, failure = SentientSystems_FindUnit(playerID, unitID)

	if failure ~= nil then
		return nil, failure
	end

	if not GameInfo.Units[spy:GetUnitType()].Spy then
		return nil, "This kind of unit isn't a spy."
	end

	if not spy:IsReadyToMove() then
		return nil, "The spy is on a mission or on its way."
	end

	if UnitManager.GetActivityType(spy) ~= ActivityTypes.ACTIVITY_AWAKE then
		return nil, SentientSystems_GetOrderFailure(spy, "start a mission", true)
	end

	return spy, nil
end

-- Returns a field of the missions, once each and joined, for the reason a
-- mission or a district isn't one of them.
local function ListField(missions, field)
	local values = {}
	local seen = {}

	for _, mission in ipairs(missions) do
		if not seen[mission[field]] then
			seen[mission[field]] = true
			values[#values + 1] = mission[field]
		end
	end

	return #values > 0 and table.concat(values, ", ") or "none"
end

-- Returns the mission in the list that has the type and, when given, the
-- district. A mission that targets several districts has an entry for each.
local function FindMission(missions, missionType, districtType)
	for _, mission in ipairs(missions) do
		if mission.type == missionType and (districtType == nil or mission.district == districtType) then
			return mission
		end
	end

	return nil
end

-- Returns the reason a mission can't start, or nil. missions is what the spy
-- can start in its city, and a mission the game refuses carries its reasons.
local function GetMissionFailure(missions, missionType, districtType)
	local mission = FindMission(missions, missionType, districtType)

	if mission == nil and districtType ~= nil and FindMission(missions, missionType, nil) ~= nil then
		return "The spy can't guard " .. districtType .. ". The districts are " .. ListField(missions, "district") .. "."
	end

	if mission == nil then
		return "The spy can't start " .. tostring(missionType) .. " here. It can start " .. ListField(missions, "type") .. "."
	end

	if mission.disabled ~= nil then
		return table.concat(mission.disabled, " ")
	end

	return nil
end

-- Returns the district of the city by its type. The caller has checked that the
-- city has it, because the district came from the spy's missions.
local function FindDistrictByType(city, districtType)
	for _, district in city:GetDistricts():Members() do
		if GameInfo.Districts[district:GetType()].DistrictType == districtType then
			return district
		end
	end
end

-- Returns the operation row of the spy mission and whether it is a counterspy
-- mission, or nil and the reason. A counterspy mission needs the district to
-- guard. missions is what the spy can start in its city.
local function FindSpyOperation(missions, mission, district)
	local operation = GameInfo.UnitOperations[tostring(mission)]
	local counterspy = operation ~= nil and operation.OperationType == "UNITOPERATION_SPY_COUNTERSPY"

	if operation == nil or not counterspy and operation.CategoryInUI ~= "OFFENSIVESPY" then
		return nil, nil, tostring(mission) .. " isn't a spy mission. The spy can start " .. ListField(missions, "type") .. "."
	end

	if counterspy and district == nil then
		return nil, nil, "A counterspy mission needs the district to guard. The districts are " .. ListField(missions, "district") .. "."
	end

	return operation, counterspy, nil
end

-- Requests the mission. A counterspy mission targets the district's tile, and
-- the others take no target.
local function StartMission(spy, city, operation, counterspy, district)
	if not counterspy then
		UnitManager.RequestOperation(spy, operation.Hash)

		return nil
	end

	local target = FindDistrictByType(city, district)

	UnitManager.RequestOperation(spy, UnitOperationTypes.SPY_COUNTERSPY, SentientSystems_GetTileParams(UnitOperationTypes, target:GetX(), target:GetY()))

	return nil
end

local function SpyMission(playerID, unitID, mission, district)
	local spy, failure = FindReadySpy(playerID, unitID)

	if failure ~= nil then
		return failure
	end

	local city = Cities.GetPlotPurchaseCity(spy:GetX(), spy:GetY())

	if city == nil then
		return "The spy isn't in a city. Send it to one first."
	end

	local missions = SentientSystems_GetSpyCityMissions(Players[playerID], spy, city)
	local operation, counterspy

	operation, counterspy, failure = FindSpyOperation(missions, mission, district)

	if failure ~= nil then
		return failure
	end

	failure = GetMissionFailure(missions, mission, counterspy and district or nil)

	if failure ~= nil then
		return failure
	end

	return StartMission(spy, city, operation, counterspy, district)
end

-- Starts a mission in the city the spy stands in, and returns the result as
-- JSON. mission is the type of a mission from the spy missions choice, such as
-- a counterspy or a siphon. A counterspy mission also takes the district to
-- guard. The game starts the other missions with no target, as the mission
-- briefing does, so a district isn't needed. An ok result means the mission has
-- begun, not that it has finished.
function SentientSystems_SpyMission(playerID, unitID, mission, district)
	return SentientSystems_RunAction("SpyMission", SpyMission, playerID, unitID, mission, district)
end

-- Returns why the spy can't travel to the city, or nil. It must be free to
-- travel, not already there, and the city must be one of its destinations.
local function GetTravelFailure(player, spy, city, name)
	if not SentientSystems_CanSpyTravel(spy) then
		return "The game won't send the spy to another city now."
	end

	local here = Cities.GetPlotPurchaseCity(spy:GetX(), spy:GetY())

	if here ~= nil and here:GetOwner() == city:GetOwner() and here:GetID() == city:GetID() then
		return "The spy is already in " .. name .. "."
	end

	for _, destination in ipairs(SentientSystems_GetSpyDestinations(player, spy)) do
		if destination.owner == city:GetOwner() and destination.id == city:GetID() then
			return nil
		end
	end

	return name .. " isn't a destination of this spy. Pick a city from its destinations in the spy missions choice."
end

local function SpyTravel(playerID, unitID, ownerID, cityID)
	local spy, failure = FindReadySpy(playerID, unitID)

	if failure ~= nil then
		return failure
	end

	local city

	city, failure = SentientSystems_FindCity(ownerID, cityID)

	if failure ~= nil then
		return failure
	end

	local name = Locale.Lookup(city:GetName())

	failure = GetTravelFailure(Players[playerID], spy, city, name)

	if failure ~= nil then
		return failure
	end

	local params = SentientSystems_GetTileParams(UnitOperationTypes, city:GetX(), city:GetY())

	return SentientSystems_RequestUnitOperation(spy, UnitOperationTypes.SPY_TRAVEL_NEW_CITY, params, "The game won't send the spy to " .. name .. ".", Map.GetPlot(city:GetX(), city:GetY()))
end

-- Sends the spy to a city of the spy missions choice, named by its owner and
-- its ID, and returns the result as JSON. An ok result means the spy has set
-- out, not that it has arrived.
function SentientSystems_SpyTravel(playerID, unitID, ownerID, cityID)
	return SentientSystems_RunAction("SpyTravel", SpyTravel, playerID, unitID, ownerID, cityID)
end

-- Returns why the escaping spy can't take the route, or nil. This follows the
-- escape screen's buttons, which turn off a route the city has no district for.
local function GetEscapeRouteFailure(escape, route)
	if escape == nil then
		return "You have no spy escaping. The spies choice lists one when a spy is caught."
	end

	local open = {}

	for _, option in ipairs(escape.routes) do
		if option.type == route then
			return option.blocked and option.blocked[1] or nil
		end

		if not option.blocked then
			open[#open + 1] = option.type
		end
	end

	return tostring(route) .. " isn't an escape route. Use one of " .. table.concat(open, ", ") .. "."
end

local function ChooseEscapeRoute(playerID, route)
	local escape = SentientSystems_GetNextEscape(SentientSystems_GetPlayer(playerID))
	local failure = GetEscapeRouteFailure(escape, route)

	if failure ~= nil then
		return failure
	end

	-- Each button of the escape screen sends its district. See OnButton1.
	local params = { [PlayerOperations.PARAM_DISTRICT_TYPE] = GameInfo.Districts[route].Index }

	UI.RequestPlayerOperation(playerID, PlayerOperations.SET_ESCAPE_ROUTE, params)

	return nil
end

-- Chooses the escaping spy's route, the type of one of its routes in the spies
-- choice, and returns the result as JSON.
function SentientSystems_ChooseEscapeRoute(playerID, route)
	return SentientSystems_RunAction("ChooseEscapeRoute", ChooseEscapeRoute, playerID, route)
end
