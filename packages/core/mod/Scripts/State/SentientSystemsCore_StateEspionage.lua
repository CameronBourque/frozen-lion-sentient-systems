-- The espionage section, as the Espionage screen shows it. Follows
-- EspionageOverview.lua. Shape: bridge/src/state/espionage.ts.

-- Returns the name of a spy's rank. See GetSpyRankNameByLevel in
-- EspionageSupport.lua.
local function GetRank(level)
	if level >= 2 and level <= 4 then
		return Locale.Lookup("LOC_ESPIONAGE_LEVEL_" .. level .. "_NAME")
	end

	return Locale.Lookup("LOC_ESPIONAGE_LEVEL_1_NAME")
end

-- Returns a city's owner, ID, and name, or nil with no city.
local function GetCityRef(city)
	if city == nil then
		return nil
	end

	return { owner = city:GetOwner(), id = city:GetID(), name = Locale.Lookup(city:GetName()) }
end

-- Returns the type of the district on the tile, or nil with none.
local function GetDistrictType(x, y)
	local district = GameInfo.Districts[Map.GetPlot(x, y):GetDistrictType()]

	return district and district.DistrictType or nil
end

-- Returns a spy on the map, idle or on a mission, with its city and the turns
-- the mission has left. See AddOperative.
local function GetSpy(spy)
	local operationType = spy:GetSpyOperation()
	local level = spy:GetExperience():GetLevel()
	local entry = {
		status = operationType == -1 and "idle" or "mission",
		id = spy:GetID(),
		name = Locale.Lookup(spy:GetName()),
		level = level,
		rank = GetRank(level),
		city = GetCityRef(Cities.GetPlotPurchaseCity(spy:GetX(), spy:GetY())),
	}

	if operationType ~= -1 then
		local operation = GameInfo.UnitOperations[operationType]

		entry.operation = {
			type = operation.OperationType,
			name = Locale.Lookup(operation.Description),
			turnsLeft = math.max(spy:GetSpyOperationEndTurn() - Game.GetCurrentGameTurn(), 0),
			totalTurns = UnitManager.GetTimeToComplete(operationType, spy),
			district = GetDistrictType(spy:GetX(), spy:GetY()),
		}
	end

	return entry
end

-- Returns the player's spies on the map, the idle ones first. See
-- RefreshOperatives.
local function GetSpies(player)
	local idle, active = {}, {}

	for _, unit in player:GetUnits():Members() do
		if GameInfo.Units[unit:GetUnitType()].Spy then
			local list = unit:GetSpyOperation() == -1 and idle or active

			list[#list + 1] = GetSpy(unit)
		end
	end

	for _, spy in ipairs(active) do
		idle[#idle + 1] = spy
	end

	return idle
end

-- Returns the player's spies that other players hold. A captured spy is listed
-- by the captor's diplomacy, with the index that a deal for it uses. See
-- AddCapturedOperative.
local function GetCaptured(player)
	local captured = {}

	for _, other in ipairs(Game.GetPlayers()) do
		local diplomacy = other:GetDiplomacy()

		for i = 0, diplomacy:GetNumSpiesCaptured() - 1 do
			local spy = diplomacy:GetNthCapturedSpy(other:GetID(), i)

			if spy ~= nil and spy.OwningPlayer == player:GetID() then
				captured[#captured + 1] = {
					status = "captured",
					name = Locale.Lookup(spy.Name),
					level = spy.Level,
					rank = GetRank(spy.Level),
					capturedBy = other:GetID(),
					captive = spy.NameIndex,
				}
			end
		end
	end

	return captured
end

-- Returns the player's spies on their way to a city. See AddOffMapOperative.
local function GetTraveling(player)
	local traveling = {}
	local diplomacy = player:GetDiplomacy()

	for i = 0, diplomacy:GetNumSpiesOffMap() - 1 do
		local spy = diplomacy:GetNthOffMapSpy(player:GetID(), i)

		if spy ~= nil and spy.ReturnTurn ~= -1 then
			traveling[#traveling + 1] = {
				status = "traveling",
				name = Locale.Lookup(spy.Name),
				level = spy.Level,
				rank = GetRank(spy.Level),
				city = GetCityRef(Cities.GetPlotPurchaseCity(spy.XLocation, spy.YLocation)),
				turnsLeft = spy.ReturnTurn - Game.GetCurrentGameTurn(),
			}
		end
	end

	return traveling
end

-- Returns a city's finished districts by type, without wonders, as the City
-- Activity tab draws them. See AddDistrictIcon.
local function GetDistricts(city)
	local districts = {}

	for _, district in city:GetDistricts():Members() do
		local info = GameInfo.Districts[district:GetType()]

		if district:IsComplete() and info ~= nil and info.DistrictType ~= "DISTRICT_WONDER" then
			districts[#districts + 1] = info.DistrictType
		end
	end

	return districts
end

-- Returns the cities of the other major players on tiles the player has
-- revealed, with their districts and the turns a Gain Sources boost has left.
-- The player's own cities are in the cities section. See AddPlayerCities and
-- AddCity.
local function GetActivity(player)
	local visibility = PlayersVisibility[player:GetID()]
	local diplomacy = player:GetDiplomacy()
	local cities = {}

	for _, other in ipairs(Game.GetPlayers()) do
		if other:GetID() ~= player:GetID() and other:IsMajor() then
			for _, city in other:GetCities():Members() do
				if visibility:IsRevealed(city:GetX(), city:GetY()) then
					local turns = diplomacy:GetSourceTurnsRemaining(city)

					cities[#cities + 1] = {
						owner = other:GetID(),
						id = city:GetID(),
						districts = GetDistricts(city),
						sourcesTurnsLeft = turns > 0 and turns or nil,
					}
				end
			end
		end
	end

	return cities
end

-- Returns what a mission stole, as the screen words it, or nil when the game
-- recorded no loot. See GetMissionLootString in EspionageSupport.lua.
local function GetLoot(mission, operation)
	if mission.LootInfo < 0 then
		return nil
	end

	if operation.Hash == UnitOperationTypes.SPY_STEAL_TECH_BOOST then
		return Locale.Lookup(GameInfo.Technologies[mission.LootInfo].Name)
	elseif operation.Hash == UnitOperationTypes.SPY_GREAT_WORK_HEIST then
		return Locale.Lookup(GameInfo.GreatWorks[Game.GetGreatWorkTypeFromIndex(mission.LootInfo)].Name)
	elseif operation.Hash == UnitOperationTypes.SPY_SIPHON_FUNDS then
		if mission.LootInfo == 0 then
			return SentientSystems_LookupText("LOC_ESPIONAGEOVERVIEW_MISSIONOUTCOME_NO_GOLD")
		end

		return SentientSystems_LookupText("LOC_ESPIONAGEOVERVIEW_MISSIONOUTCOME_GOLD", mission.LootInfo)
	end

	return nil
end

-- What each way a mission can end gives: whether the screen calls it a success,
-- what became of the spy, and the part of the text's key that names it. A
-- detected spy has a second result, for its escape. See
-- GetMissionOutcomeDetails in EspionageSupport.lua.
local function GetOutcome(mission)
	local results = EspionageResultTypes
	local initial, escape = mission.InitialResult, mission.EscapeResult

	if initial == results.SUCCESS_UNDETECTED then
		return true, nil, "SUCCESS_UNDETECTED"
	elseif initial == results.FAIL_UNDETECTED then
		return false, nil, "FAILURE_UNDETECTED"
	elseif initial == results.KILLED then
		return false, "killed", "KILLED"
	elseif initial == results.CAPTURED then
		return false, "captured", "CAPTURED"
	end

	local success = initial == results.SUCCESS_MUST_ESCAPE
	local prefix = success and "SUCCESS_DETECTED_" or "FAILURE_DETECTED_"

	if escape == results.KILLED then
		return false, "killed", prefix .. "KILLED"
	elseif escape == results.CAPTURED then
		return false, "captured", prefix .. "CAPTURED"
	end

	return success, "escaped", prefix .. "ESCAPED"
end

-- Returns one past mission, or nil for one whose spy has yet to pick an escape
-- route. See AddMissionHistoryInstance.
local function GetMission(mission)
	local results = EspionageResultTypes

	if (mission.InitialResult == results.SUCCESS_MUST_ESCAPE or mission.InitialResult == results.FAIL_MUST_ESCAPE)
		and mission.EscapeResult == results.NO_RESULT then
		return nil
	end

	local operation = GameInfo.UnitOperations[mission.Operation]
	local loot = GetLoot(mission, operation)
	local city = Locale.Lookup(mission.CityName)
	local success, fate, key = GetOutcome(mission)
	local description

	if operation.Hash == UnitOperationTypes.SPY_COUNTERSPY then
		success, fate = true, nil
		description = SentientSystems_LookupText("LOC_ESPIONAGEOVERVIEW_MISSIONOUTCOME_SUCCESS_COUNTERSPY", city)
	elseif loot ~= nil then
		-- The game words the loot of a detected success that escaped with its
		-- own key, with no ESCAPED in it.
		local lootKey = key == "SUCCESS_DETECTED_ESCAPED" and "SUCCESS_DETECTED" or key

		description = SentientSystems_LookupText("LOC_ESPIONAGEOVERVIEW_MISSIONOUTCOME_" .. lootKey .. "_STOLELOOT", loot, city)
	else
		description = SentientSystems_LookupText("LOC_ESPIONAGEOVERVIEW_MISSIONOUTCOME_" .. key, city)
	end

	return {
		name = Locale.Lookup(mission.Name),
		level = mission.LevelAfter,
		rank = GetRank(mission.LevelAfter),
		operation = { type = operation.OperationType, name = Locale.Lookup(operation.Description) },
		turnsAgo = Game.GetCurrentGameTurn() - mission.CompletionTurn,
		city = city,
		success = success,
		fate = fate,
		loot = loot,
		description = description,
	}
end

-- Returns the player's last 10 missions, the newest first, as the Mission
-- History tab lists them. See RefreshMissionHistory.
local function GetHistory(player)
	local history = {}

	for _, mission in pairs(player:GetDiplomacy():GetRecentMissions(player:GetID(), 10, 0) or {}) do
		history[#history + 1] = GetMission(mission)
	end

	return history
end

-- Returns the other players' spies that the player holds, with the index a
-- deal to trade one back uses. See RefreshMissionHistory.
local function GetCaptives(player)
	local captives = {}
	local diplomacy = player:GetDiplomacy()

	for i = 0, diplomacy:GetNumSpiesCaptured() - 1 do
		local spy = diplomacy:GetNthCapturedSpy(player:GetID(), i)

		if spy ~= nil then
			captives[#captives + 1] = {
				name = Locale.Lookup(spy.Name),
				owner = spy.OwningPlayer,
				level = spy.Level,
				rank = GetRank(spy.Level),
				captive = spy.NameIndex,
			}
		end
	end

	return captives
end

-- Returns the espionage section: the spy capacity, every spy the player has,
-- in the screen's order, the idle and active ones, the captured ones, and the
-- ones on the way, the other majors' cities as the City Activity tab lists
-- them, and the Mission History tab's missions and held spies.
function SentientSystems_GetEspionageState(player)
	local operatives = GetSpies(player)

	for _, list in ipairs({ GetCaptured(player), GetTraveling(player) }) do
		for _, spy in ipairs(list) do
			operatives[#operatives + 1] = spy
		end
	end

	return {
		capacity = player:GetDiplomacy():GetSpyCapacity(),
		operatives = operatives,
		cities = GetActivity(player),
		history = GetHistory(player),
		captives = GetCaptives(player),
	}
end
