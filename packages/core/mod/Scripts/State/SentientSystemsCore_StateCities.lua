-- The cities section: the player's own cities, as the city panel shows them.
-- Shape: bridge/src/state/cities.ts.

-- Each yield in the state, and its name in YieldTypes.
local YIELDS = {
	culture = "CULTURE",
	faith = "FAITH",
	food = "FOOD",
	gold = "GOLD",
	production = "PRODUCTION",
	science = "SCIENCE",
}

-- Returns what the city is producing, with the turns left, or nil when it
-- produces nothing. A hash of 0 means nothing. GameInfo reads 0 as a row index,
-- so GameInfo.Types[0] is the first row, not the production. See
-- docs/findings/state/state.md.
local function GetProduction(city)
	local queue = city:GetBuildQueue()
	local hash = queue:GetCurrentProductionTypeHash()

	if hash == 0 then
		return nil
	end

	local row = GameInfo.Types[hash]

	return { type = row and row.Type, turnsLeft = queue:GetTurnsLeft(hash) }
end

-- Rounds a number down to one decimal place, as the city panel does.
local function RoundDown(number)
	return math.floor(number * 10) / 10
end

-- Rounds a number to the nearest tenth, as the city panel does for loyalty.
local function RoundNearest(number)
	return math.floor(number * 10 + 0.5) / 10
end

-- Returns each yield per turn, rounded down as the city panel shows it.
local function GetYields(city)
	local yields = {}

	for key, name in pairs(YIELDS) do
		yields[key] = RoundDown(city:GetYield(YieldTypes[name]))
	end

	return yields
end

-- Returns the city's growth rate status as the City Status tab of Reports shows
-- it: halted without room to grow or while the city is occupied, slowed at half
-- the rate or less, accelerated when its amenities speed it up, and normal
-- otherwise. See CreateCityStatusInstance in ReportScreen.lua.
local function GetGrowthRate(city, growth)
	local housingModifier = growth:GetHousingGrowthModifier()

	if housingModifier == 0 or city:IsOccupied() then
		return "halted"
	elseif housingModifier <= 0.5 then
		return "slowed"
	elseif growth:GetHappinessGrowthModifier() > 0 then
		return "accelerated"
	end

	return "normal"
end

-- Returns the food surplus per turn, the housing, the growth rate status, and
-- the turns until the city grows or, when it starves, until it loses a citizen.
-- The game returns -1 for each count that doesn't apply, and a city that
-- neither grows nor starves has neither count, as in GetCityData in
-- CitySupport.lua.
local function GetGrowth(city)
	local growth = city:GetGrowth()
	local result = {
		foodSurplus = RoundDown(growth:GetFoodSurplus()),
		housing = RoundDown(growth:GetHousing()),
		rate = GetGrowthRate(city, growth),
	}
	local turnsUntilGrowth = growth:GetTurnsUntilGrowth()

	if turnsUntilGrowth ~= -1 then
		result.turnsUntilGrowth = turnsUntilGrowth
	else
		local turnsUntilLoss = growth:GetTurnsUntilStarvation()

		if turnsUntilLoss ~= -1 then
			result.turnsUntilLoss = turnsUntilLoss
		end
	end

	return result
end

-- Returns the amenities the city has and needs, its mood, and the amenities it
-- loses to war weariness. The city panel shows have minus need.
local function GetAmenities(city)
	local growth = city:GetGrowth()
	local mood = GameInfo.Happinesses[growth:GetHappiness()]

	return {
		have = growth:GetAmenities(),
		need = growth:GetAmenitiesNeeded(),
		mood = mood and mood.HappinessType,
		warWeariness = growth:GetAmenitiesLostFromWarWeariness(),
	}
end

-- Returns the city's governor, with type and established, whether they have
-- settled in, or nil for none, and in a game without Rise and Fall, which adds
-- governors. See CreateCityStatusInstance in ReportScreen_Expansion1.lua.
local function GetGovernor(city)
	local governor = city.GetAssignedGovernor ~= nil and city:GetAssignedGovernor()

	if not governor then
		return nil
	end

	return { type = GameInfo.Governors[governor:GetType()].GovernorType, established = governor:IsEstablished() }
end

-- Returns the city's loyalty, its most, and its change per turn, rounded as the
-- city panel shows them, or nil in a game without loyalty. Loyalty comes with
-- the Rise and Fall expansion, which adds GetCulturalIdentity. See
-- CityPanelCulture.lua in DLC/Expansion1.
local function GetLoyalty(city)
	if city.GetCulturalIdentity == nil then
		return nil
	end

	local identity = city:GetCulturalIdentity()

	return {
		value = RoundNearest(identity:GetLoyalty()),
		max = identity:GetMaxLoyalty(),
		perTurn = RoundNearest(identity:GetLoyaltyPerTurn()),
	}
end

-- Returns the city's districts, each with its built buildings. A district that
-- is placed but not built yet has complete set to false. Wonders sit in their
-- own DISTRICT_WONDER. GetCityData in CitySupport.lua reads the same calls.
local function GetDistricts(city)
	local buildings = city:GetBuildings()
	local districts = {}

	for _, district in city:GetDistricts():Members() do
		local plotIndex = Map.GetPlot(district:GetX(), district:GetY()):GetIndex()
		local built = {}

		for _, index in ipairs(buildings:GetBuildingsAtLocation(plotIndex)) do
			if buildings:HasBuilding(index) then
				built[#built + 1] = { type = GameInfo.Buildings[index].BuildingType, pillaged = buildings:IsPillaged(index) }
			end
		end

		districts[#districts + 1] = {
			type = GameInfo.Districts[district:GetType()].DistrictType,
			x = district:GetX(),
			y = district:GetY(),
			complete = district:IsComplete(),
			pillaged = district:IsPillaged(),
			buildings = built,
		}
	end

	return districts
end

-- Returns the defense that a city's banner shows: its strength, rounded as the
-- banner rounds it, the garrison's health, and the walls' health. walls is left
-- out for a city with none. The banner reads the city center district, in
-- CityBanner:UpdateStats in CityBannerManager.lua. The rivals section uses it
-- too.
function SentientSystems_GetCityDefense(player, city)
	local center = player:GetDistricts():FindID(city:GetDistrictID())
	local garrison, walls = DefenseTypes.DISTRICT_GARRISON, DefenseTypes.DISTRICT_OUTER
	local defense = {
		strength = math.floor(center:GetDefenseStrength() + 0.5),
		garrison = SentientSystems_GetHealth(center:GetMaxDamage(garrison), center:GetDamage(garrison)),
	}

	if center:GetMaxDamage(walls) > 0 then
		defense.walls = SentientSystems_GetHealth(center:GetMaxDamage(walls), center:GetDamage(walls))
	end

	return defense
end

-- Rounds a number to the nearest whole number, as the banner rounds a pressure.
local function RoundWhole(number)
	return math.floor(number + 0.5)
end

-- Returns the religion the city will convert to and in how many turns, or nil.
-- The banner shows it for a next religion that isn't -1, at more than 0 turns.
local function GetConversion(cityReligion)
	local nextReligion = cityReligion:GetNextReligion()
	local turns = cityReligion:GetTurnsToNextReligion()

	if nextReligion ~= nil and nextReligion ~= -1 and turns > 0 then
		return { type = GameInfo.Religions[nextReligion].ReligionType, turns = turns }
	end

	return nil
end

-- Returns the city's religions: the majority, the pressure the city exerts, and
-- for each religion present its followers, the pressure on the city each turn,
-- and the pressure it has received in all. The banner shows the majority above
-- 0, and each pressure rounded: GetPressureFromCity for the pressure exerted,
-- GetTotalPressureOnCity for the pressure each turn, and the list's own
-- Pressure for the total. CitySupport.lua names the entry for citizens with no
-- religion, whose index is below 1, RELIGION_PANTHEON, and the banner shows no
-- pressure for it, and the conversion. See docs/findings/state/city-details.md.
-- The rivals section uses it too.
function SentientSystems_GetCityReligion(city)
	local cityReligion = city:GetReligion()
	local majority = cityReligion:GetMajorityReligion()
	local present = {}

	for _, entry in ipairs(cityReligion:GetReligionsInCity()) do
		local pantheon = entry.Religion <= 0

		present[#present + 1] = {
			type = pantheon and "RELIGION_PANTHEON" or GameInfo.Religions[entry.Religion].ReligionType,
			followers = entry.Followers,
			pressure = not pantheon and RoundWhole(cityReligion:GetTotalPressureOnCity(entry.Religion)) or nil,
			totalPressure = not pantheon and RoundWhole(entry.Pressure) or nil,
		}
	end

	return {
		majority = majority > 0 and GameInfo.Religions[majority].ReligionType or nil,
		outwardPressure = RoundWhole(cityReligion:GetPressureFromCity()),
		present = present,
		converting = GetConversion(cityReligion),
	}
end

-- Returns a list of the player's cities, with each city's name in the game's
-- language.
function SentientSystems_GetCityStates(player)
	local cities = {}

	for _, city in player:GetCities():Members() do
		cities[#cities + 1] = {
			id = city:GetID(),
			name = Locale.Lookup(city:GetName()),
			x = city:GetX(),
			y = city:GetY(),
			population = city:GetPopulation(),
			amenities = GetAmenities(city),
			defense = SentientSystems_GetCityDefense(player, city),
			districts = GetDistricts(city),
			governor = GetGovernor(city),
			growth = GetGrowth(city),
			loyalty = GetLoyalty(city),
			production = GetProduction(city),
			religion = SentientSystems_GetCityReligion(city),
			yields = GetYields(city),
		}
	end

	return cities
end
