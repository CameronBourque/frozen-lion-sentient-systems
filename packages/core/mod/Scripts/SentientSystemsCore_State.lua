-- Builds one player's view of the game as JSON for the bridge, from that player's own data and
-- visibility, never from the screen. See docs/design/core/in-game-lua.md. Example:
-- SentientSystems_GetState(0) returns
-- '{"cities":[{"id":65536,"name":"Aduatuca","population":1,"x":42,"y":49}]}'.

include("SentientSystemsCore_Common")
SentientSystems_Include("SentientSystemsCore_Json")

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
