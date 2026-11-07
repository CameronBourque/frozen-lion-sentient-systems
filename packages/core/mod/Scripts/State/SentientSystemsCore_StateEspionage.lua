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

-- Returns the espionage section: the spy capacity, every spy the player has,
-- in the screen's order, the idle and active ones, the captured ones, and the
-- ones on the way, and the other majors' cities as the City Activity tab lists
-- them.
function SentientSystems_GetEspionageState(player)
	local operatives = GetSpies(player)

	for _, list in ipairs({ GetCaptured(player), GetTraveling(player) }) do
		for _, spy in ipairs(list) do
			operatives[#operatives + 1] = spy
		end
	end

	return { capacity = player:GetDiplomacy():GetSpyCapacity(), operatives = operatives, cities = GetActivity(player) }
end
