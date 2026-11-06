-- The spy missions choice: each ready spy's trips and missions. Follows
-- EspionageChooser.lua, EspionageSupport.lua, and EspionagePopup.lua.
-- Shape: bridge/src/choices/spy-missions.ts.

local function GetCityRef(city)
	return { owner = city:GetOwner(), id = city:GetID(), name = Locale.Lookup(city:GetName()) }
end

-- Returns the types of the districts the chooser shows as icons for a city:
-- the complete ones, wonders left out.
local function GetDistrictTypes(city)
	local types = {}

	for _, district in city:GetDistricts():Members() do
		local districtType = GameInfo.Districts[district:GetType()].DistrictType

		if district:IsComplete() and districtType ~= "DISTRICT_WONDER" then
			types[#types + 1] = districtType
		end
	end

	return types
end

-- Returns whether the chooser lists the player's cities: every player but an
-- ally, a teammate, and the Free Cities, with the cities the player has seen.
-- See RefreshDestinationList in EspionageChooser_Expansion1.lua.
local function ListsPlayer(player, other)
	local state = other:GetDiplomaticAI():GetDiplomaticStateIndex(player:GetID())

	if state == -1 or GameInfo.DiplomaticStates[state].StateType == "DIPLO_STATE_ALLIED" or other:IsFreeCities() then
		return false
	end

	return other:GetID() == player:GetID() or other:GetTeam() == -1 or player:GetTeam() == -1 or other:GetTeam() ~= player:GetTeam()
end

-- Returns the cities the spy can travel to, as the chooser lists them, with
-- the turns to get there and to settle in. See AddDestination.
function SentientSystems_GetSpyDestinations(player, spy)
	local visibility = PlayersVisibility[player:GetID()]
	local destinations = {}

	for _, other in ipairs(Game.GetPlayers()) do
		if ListsPlayer(player, other) then
			for _, city in other:GetCities():Members() do
				if visibility:IsRevealed(city:GetX(), city:GetY()) then
					local destination = GetCityRef(city)
					local travel = UnitManager.GetTravelTime(spy, city)
					local establish = UnitManager.GetEstablishInCityTime(spy, city)

					destination.capital = city:IsCapital() and other:IsMajor() or nil
					destination.turns = travel + establish
					destination.travel = travel
					destination.establish = establish
					destination.districts = GetDistrictTypes(city)
					destinations[#destinations + 1] = destination
				end
			end
		end
	end

	return destinations
end

-- Returns the district of the city on the plot, or nil.
local function FindDistrict(city, plot)
	for _, district in city:GetDistricts():Members() do
		if district:GetX() == plot:GetX() and district:GetY() == plot:GetY() then
			return GameInfo.Districts[district:GetType()]
		end
	end

	return nil
end

-- Returns the text under a mission's name. See GetFormattedOperationDetailText
-- in EspionageSupport.lua.
local function GetDetails(operation, spy, city)
	local details = UnitManager.GetOperationDetailText(operation.Index, spy, Map.GetPlot(city:GetX(), city:GetY()))
	local type = operation.OperationType

	if type == "UNITOPERATION_SPY_GREAT_WORK_HEIST" or type == "UNITOPERATION_SPY_FOMENT_UNREST" or type == "UNITOPERATION_SPY_FABRICATE_SCANDAL" or type == "UNITOPERATION_SPY_NEUTRALIZE_GOVERNOR" then
		return Locale.Lookup("LOC_SPYMISSIONDETAILS_" .. type, details)
	end

	if type == "UNITOPERATION_SPY_SIPHON_FUNDS" then
		return Locale.Lookup("LOC_SPYMISSIONDETAILS_" .. type, Locale.ToUpper(city:GetName()), details)
	end

	if details ~= "" then
		return details
	end

	return Locale.Lookup("LOC_SPYMISSIONDETAILS_" .. type)
end

-- Returns the chances of an offensive mission as whole percents, and the
-- warning that its target will learn who did it. See RefreshPossibleOutcomes in
-- EspionagePopup.lua, which adds the discovered warning only when the mission
-- can fail and the target isn't a city-state. Returns nil when the game gives
-- no success chance.
local function GetChances(operation, spy, plot, city)
	local probability = UnitManager.GetResultProbability(operation.Index, spy, plot)
	local success = probability["ESPIONAGE_SUCCESS_UNDETECTED"]

	if success == nil then
		return nil, nil
	end

	local percent = math.floor((success + (probability["ESPIONAGE_SUCCESS_MUST_ESCAPE"] or 0)) * 100 + 0.5)
	local chances = { success = percent }

	if percent >= 100 then
		return chances, nil
	end

	local failure = math.floor(((probability["ESPIONAGE_FAIL_UNDETECTED"] or 0) + (probability["ESPIONAGE_FAIL_MUST_ESCAPE"] or 0)) * 100 + 0.5)

	chances.failure = failure > 0 and failure or nil
	chances.captured = 100 - percent - failure > 0 and 100 - percent - failure or nil

	if Players[city:GetOwner()]:GetInfluence():CanReceiveInfluence() then
		return chances, nil
	end

	return chances, Locale.Lookup("LOC_ESPIONAGEPOPUP_DISCOVERED_WARNING", PlayerConfigurations[city:GetOwner()]:GetPlayerName())
end

-- Returns one offensive mission at a target plot, as the chooser and the
-- briefing show it. A mission with no target district uses the city center.
local function GetOffensiveMission(operation, spy, city, targetPlot, districtRow)
	local district = districtRow or GameInfo.Districts["DISTRICT_CITY_CENTER"]
	local chances, warning = GetChances(operation, spy, targetPlot, city)

	return {
		type = operation.OperationType,
		name = Locale.Lookup(operation.Description),
		district = district.DistrictType,
		districtName = Locale.Lookup(district.Name),
		details = GetDetails(operation, spy, city),
		turns = UnitManager.GetTimeToComplete(operation.Index, spy),
		chances = chances,
		warning = warning,
	}
end

-- Returns the offensive missions the spy can start in a city of another player,
-- and those that the game refuses with reasons. See RefreshMissionList.
local function GetOffensiveMissions(spy, city)
	local cityPlot = Map.GetPlot(city:GetX(), city:GetY())
	local missions = {}

	for operation in GameInfo.UnitOperations() do
		if operation.CategoryInUI == "OFFENSIVESPY" then
			local canStart, results = UnitManager.CanStartOperation(spy, operation.Hash, cityPlot, false, true)

			if canStart then
				local plots = results and results[UnitOperationResults.PLOTS] or {}
				local added = false

				for _, index in ipairs(plots) do
					local plot = Map.GetPlotByIndex(index)

					if plot ~= nil then
						missions[#missions + 1] = GetOffensiveMission(operation, spy, city, plot, FindDistrict(city, plot))
						added = true
					end
				end

				if not added then
					missions[#missions + 1] = GetOffensiveMission(operation, spy, city, cityPlot, nil)
				end
			elseif results and results[UnitOperationResults.FAILURE_REASONS] then
				local reasons = {}

				for i, reason in ipairs(results[UnitOperationResults.FAILURE_REASONS]) do
					reasons[i] = Locale.Lookup(reason)
				end

				local mission = GetOffensiveMission(operation, spy, city, cityPlot, nil)

				mission.disabled = reasons
				missions[#missions + 1] = mission
			end
		end
	end

	return missions
end

-- Returns the counterspy missions in a city of the player, one for each
-- district it can guard. See AddCounterspyOperation.
local function GetCounterspyMissions(spy, city)
	local cityPlot = Map.GetPlot(city:GetX(), city:GetY())
	local missions = {}

	for operation in GameInfo.UnitOperations() do
		if operation.OperationType == "UNITOPERATION_SPY_COUNTERSPY" then
			local canStart, results = UnitManager.CanStartOperation(spy, operation.Hash, cityPlot, false, true)

			if canStart then
				for _, index in ipairs(results[UnitOperationResults.PLOTS]) do
					local district = FindDistrict(city, Map.GetPlotByIndex(index))

					if district ~= nil then
						missions[#missions + 1] = {
							type = operation.OperationType,
							name = Locale.Lookup(operation.Description),
							district = district.DistrictType,
							districtName = Locale.Lookup(district.Name),
							details = Locale.Lookup("LOC_ESPIONAGECHOOSER_COUNTERSPY", Locale.Lookup(district.Name)),
						}
					end
				end
			end
		end
	end

	return missions
end

-- Returns whether the panel offers the spy a trip to another city: the game's
-- travel operation passes for it. The chooser opens for it in a city of the
-- player's, and the panel's travel button opens it anywhere else.
function SentientSystems_CanSpyTravel(spy)
	local hash = GameInfo.UnitOperations["UNITOPERATION_SPY_TRAVEL_NEW_CITY"].Hash
	local plot = Map.GetPlot(spy:GetX(), spy:GetY())

	return UnitManager.CanStartOperation(spy, hash, plot, false, true)
end

-- Returns the missions the spy can start in the city it stands in: counterspy
-- missions in a city of the player's, and offensive ones in another's.
function SentientSystems_GetSpyCityMissions(player, spy, city)
	if city:GetOwner() == player:GetID() then
		return GetCounterspyMissions(spy, city)
	end

	return GetOffensiveMissions(spy, city)
end

-- Returns the spy missions choice: each awake spy that is ready to move, in the
-- city it stands in, with the cities it can travel to and the missions it can
-- start there. Returns nil when no spy is ready. A spy on a mission or on its
-- way isn't ready. See GoToProperInterfaceMode in EspionageChooser.lua.
function SentientSystems_GetSpyMissionChoices(player)
	local choices = {}

	for _, spy in player:GetUnits():Members() do
		local awake = UnitManager.GetActivityType(spy) == ActivityTypes.ACTIVITY_AWAKE

		if GameInfo.Units[spy:GetUnitType()].Spy and spy:IsReadyToMove() and awake then
			local city = Cities.GetPlotPurchaseCity(spy:GetX(), spy:GetY())
			local choice = { spy = spy:GetID(), name = Locale.Lookup(spy:GetName()) }

			if city ~= nil then
				choice.city = GetCityRef(city)
				choice.missions = SentientSystems_GetSpyCityMissions(player, spy, city)
			end

			if SentientSystems_CanSpyTravel(spy) then
				choice.destinations = SentientSystems_GetSpyDestinations(player, spy)
			end

			choices[#choices + 1] = choice
		end
	end

	return #choices > 0 and choices or nil
end
