-- The rivals section of the state: other players' cities that the player can know about, as their
-- city banners show them. See docs/findings/tile-visibility.md. SentientSystemsCore_State.lua loads
-- this file. Example: SentientSystems_GetRivalCityStates(playerID) returns a list with one table for
-- each city, which encodes as
-- '{"capital":true,"defense":{"garrison":{"max":200,"value":200},"strength":13},"id":65536,
-- "name":"Râ-Kedet","owner":1,"population":2,"x":30,"y":18}', on one line.

-- Returns the defense that a city's banner shows: its strength, rounded as the banner rounds it, the
-- garrison's health, and the walls' health. walls is left out for a city with none. The banner reads
-- the city center district, in CityBanner:UpdateStats in CityBannerManager.lua.
local function GetDefense(player, city)
	local center = player:GetDistricts():FindID(city:GetDistrictID())
	local garrisonMax = center:GetMaxDamage(DefenseTypes.DISTRICT_GARRISON)
	local wallsMax = center:GetMaxDamage(DefenseTypes.DISTRICT_OUTER)
	local defense = {
		strength = math.floor(center:GetDefenseStrength() + 0.5),
		garrison = { value = garrisonMax - center:GetDamage(DefenseTypes.DISTRICT_GARRISON), max = garrisonMax },
	}

	if wallsMax > 0 then
		defense.walls = { value = wallsMax - center:GetDamage(DefenseTypes.DISTRICT_OUTER), max = wallsMax }
	end

	return defense
end

-- Returns a list of the other living players' cities on tiles that the player with ID playerID has
-- revealed. A city's banner shows on a revealed tile, fogged or not. City IDs repeat across players,
-- so owner and id together name a city.
function SentientSystems_GetRivalCityStates(playerID)
	local visibility = PlayersVisibility[playerID]
	local cities = {}

	for _, player in ipairs(PlayerManager.GetAlive()) do
		local owner = player:GetID()

		if owner ~= playerID then
			for _, city in player:GetCities():Members() do
				if visibility:IsRevealed(city:GetX(), city:GetY()) then
					cities[#cities + 1] = {
						owner = owner,
						id = city:GetID(),
						name = Locale.Lookup(city:GetName()),
						x = city:GetX(),
						y = city:GetY(),
						population = city:GetPopulation(),
						capital = city:IsCapital(),
						defense = GetDefense(player, city),
					}
				end
			end
		end
	end

	return cities
end
