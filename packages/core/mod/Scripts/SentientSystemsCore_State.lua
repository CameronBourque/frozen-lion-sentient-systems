-- Builds one player's view of the game as JSON for the bridge, from that player's own data and
-- visibility, never from the screen. See docs/design/core/in-game-lua.md. Example:
-- SentientSystems_GetState(0) returns
-- '{"cities":[{"amenities":{"have":2,"mood":"HAPPINESS_CONTENT","need":2},
-- "growth":{"foodSurplus":3,"housing":6,"turnsUntilGrowth":2},"id":65536,
-- "loyalty":{"max":100,"perTurn":21,"value":100},"name":"Rome","population":3,
-- "production":{"turnsLeft":2,"type":"UNIT_SLINGER"},"x":17,"y":14,
-- "yields":{"culture":3.8,"faith":0,"food":9,"gold":8,"production":6,"science":3.5}}]}', on one line.

include("SentientSystemsCore_Common")
SentientSystems_Include("SentientSystemsCore_Json")

-- Each yield in the state, and its name in YieldTypes.
local YIELDS = {
	culture = "CULTURE",
	faith = "FAITH",
	food = "FOOD",
	gold = "GOLD",
	production = "PRODUCTION",
	science = "SCIENCE",
}

-- Returns what the city is producing, with the turns left, or nil when it produces nothing. A hash
-- of 0 means nothing. GameInfo reads 0 as a row index, so GameInfo.Types[0] is the first row, not
-- the production. See docs/findings/game-state.md.
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

-- Returns the food surplus per turn, the housing, and the turns until the city grows or, when it
-- starves, until it loses a citizen. The game returns -1 for each count that doesn't apply, and a city that neither
-- grows nor starves has neither count, as in GetCityData in CitySupport.lua.
local function GetGrowth(city)
	local growth = city:GetGrowth()
	local result = { foodSurplus = RoundDown(growth:GetFoodSurplus()), housing = RoundDown(growth:GetHousing()) }
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

-- Returns the amenities the city has and needs, and its mood, such as HAPPINESS_CONTENT. The city
-- panel shows have minus need.
local function GetAmenities(city)
	local growth = city:GetGrowth()
	local mood = GameInfo.Happinesses[growth:GetHappiness()]

	return {
		have = growth:GetAmenities(),
		need = growth:GetAmenitiesNeeded(),
		mood = mood and mood.HappinessType,
	}
end

-- Returns the city's loyalty, its most, and its change per turn, rounded as the city panel shows
-- them, or nil in a game without loyalty. Loyalty comes with the Rise and Fall expansion, which adds
-- GetCulturalIdentity. See CityPanelCulture.lua in DLC/Expansion1.
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

-- Returns the player's cities, with each city's name in the game's language.
local function GetCities(player)
	local cities = {}

	for _, city in player:GetCities():Members() do
		cities[#cities + 1] = {
			id = city:GetID(),
			name = Locale.Lookup(city:GetName()),
			x = city:GetX(),
			y = city:GetY(),
			population = city:GetPopulation(),
			amenities = GetAmenities(city),
			growth = GetGrowth(city),
			loyalty = GetLoyalty(city),
			production = GetProduction(city),
			yields = GetYields(city),
		}
	end

	return cities
end

-- Returns the state of the player with ID playerID as JSON. Raises an error for an ID with no
-- player. The bridge reads it through the stash, as
-- SentientSystems_Stash(SentientSystems_GetState(playerID)).
function SentientSystems_GetState(playerID)
	local player = Players[playerID]

	if player == nil then
		error("no player " .. tostring(playerID), 0)
	end

	return SentientSystems_EncodeJson({ cities = GetCities(player) })
end
