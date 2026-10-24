-- Builds one player's view of the game as JSON for the bridge, from that player's own data and
-- visibility, never from the screen. See docs/design/core/in-game-lua.md. Example:
-- SentientSystems_GetState(0) returns
-- '{"cities":[{"id":65536,"name":"Rome","population":3,"production":{"turnsLeft":2,"type":"UNIT_SLINGER"},
-- "x":17,"y":14,"yields":{"culture":3.8,"faith":0,"food":9,"gold":8,"production":6,"science":3.5}}]}',
-- on one line.

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

-- Returns each yield per turn, rounded down to one decimal place, as the city panel shows it.
local function GetYields(city)
	local yields = {}

	for key, name in pairs(YIELDS) do
		yields[key] = math.floor(city:GetYield(YieldTypes[name]) * 10) / 10
	end

	return yields
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
