-- The spy actions: a mission, and a trip to another city. Uses the lists of the
-- spy missions choice. The calls are in docs/findings/actions/spies.md.

SentientSystems_Include("SentientSystemsCore_ChoicesSpyMissions")

-- Returns the player's spy, or the reason it can't act. A spy takes orders
-- only when it is ready to move and awake, as the chooser opens only then. See
-- GoToProperInterfaceMode in EspionageChooser.lua.
local function GetSpy(playerID, unitID)
	local spy = UnitManager.GetUnit(playerID, unitID)

	if spy == nil then
		return nil, "Player " .. playerID .. " has no unit " .. unitID .. "."
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
local function FindDistrict(city, districtType)
	for _, district in city:GetDistricts():Members() do
		if GameInfo.Districts[district:GetType()].DistrictType == districtType then
			return district
		end
	end
end

-- Starts a mission in the city the spy stands in, and returns the result as
-- JSON. mission is the type of a mission from the spy missions choice, such as
-- a counterspy or a siphon. A counterspy mission also takes the district to
-- guard. The game starts the other missions with no target, as the mission
-- briefing does, so a district isn't needed. An ok result means the mission has
-- begun, not that it has finished.
function SentientSystems_SpyMission(playerID, unitID, mission, district)
	return SentientSystems_RunAction("SpyMission", function()
		local spy, failure = GetSpy(playerID, unitID)

		if failure ~= nil then
			return failure
		end

		local city = Cities.GetPlotPurchaseCity(spy:GetX(), spy:GetY())

		if city == nil then
			return "The spy isn't in a city. Send it to one first."
		end

		local operation = GameInfo.UnitOperations[tostring(mission)]
		local missions = SentientSystems_GetSpyCityMissions(Players[playerID], spy, city)

		local counterspy = operation ~= nil and operation.OperationType == "UNITOPERATION_SPY_COUNTERSPY"

		if operation == nil or not counterspy and operation.CategoryInUI ~= "OFFENSIVESPY" then
			return tostring(mission) .. " isn't a spy mission. The spy can start " .. ListField(missions, "type") .. "."
		end

		if counterspy and district == nil then
			return "A counterspy mission needs the district to guard. The districts are " .. ListField(missions, "district") .. "."
		end

		failure = GetMissionFailure(missions, mission, counterspy and district or nil)

		if failure ~= nil then
			return failure
		end

		if not counterspy then
			UnitManager.RequestOperation(spy, operation.Hash)

			return nil
		end

		local target = FindDistrict(city, district)

		UnitManager.RequestOperation(spy, UnitOperationTypes.SPY_COUNTERSPY, {
			[UnitOperationTypes.PARAM_X] = target:GetX(),
			[UnitOperationTypes.PARAM_Y] = target:GetY(),
		})

		return nil
	end)
end

-- Sends the spy to a city of the spy missions choice, named by its owner and
-- its ID, and returns the result as JSON. An ok result means the spy has set
-- out, not that it has arrived.
function SentientSystems_SpyTravel(playerID, unitID, ownerID, cityID)
	return SentientSystems_RunAction("SpyTravel", function()
		local spy, failure = GetSpy(playerID, unitID)

		if failure ~= nil then
			return failure
		end

		local owner = Players[ownerID]
		local cities = owner and owner:GetCities()
		local city = cities and cities:FindID(cityID)

		if city == nil then
			return "Player " .. tostring(ownerID) .. " has no city " .. tostring(cityID) .. "."
		end

		if not SentientSystems_CanSpyTravel(spy) then
			return "The game won't send the spy to another city now."
		end

		local here = Cities.GetPlotPurchaseCity(spy:GetX(), spy:GetY())

		if here ~= nil and here:GetOwner() == ownerID and here:GetID() == cityID then
			return "The spy is already in " .. Locale.Lookup(city:GetName()) .. "."
		end

		for _, destination in ipairs(SentientSystems_GetSpyDestinations(Players[playerID], spy)) do
			if destination.owner == ownerID and destination.id == cityID then
				local params = {
					[UnitOperationTypes.PARAM_X] = city:GetX(),
					[UnitOperationTypes.PARAM_Y] = city:GetY(),
				}

				if not UnitManager.CanStartOperation(spy, UnitOperationTypes.SPY_TRAVEL_NEW_CITY, Map.GetPlot(city:GetX(), city:GetY()), params) then
					return "The game won't send the spy to " .. Locale.Lookup(city:GetName()) .. "."
				end

				UnitManager.RequestOperation(spy, UnitOperationTypes.SPY_TRAVEL_NEW_CITY, params)

				return nil
			end
		end

		return Locale.Lookup(city:GetName()) .. " isn't a destination of this spy. Pick a city from its destinations in the spy missions choice."
	end)
end
