-- The rivals section of the state: other players' cities and units that the player can know about,
-- as their city banners and unit flags show them. See docs/findings/tile-visibility.md.
-- SentientSystemsCore_State.lua loads this file, after the cities and units files. Example:
-- SentientSystems_GetRivalCityStates(playerID) returns a list with one table for each city, which
-- encodes as '{"capital":true,"defense":{"garrison":{"max":200,"value":200},"strength":13},"id":65536,
-- "name":"Râ-Kedet","owner":1,"population":2,"x":30,"y":18}', on one line.
-- SentientSystems_GetRivalUnitStates(playerID) returns one table for each unit, which encodes as
-- '{"health":{"max":100,"value":100},"id":131073,"owner":1,"type":"UNIT_WARRIOR","x":25,"y":14}'.

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
						defense = SentientSystems_GetCityDefense(player, city),
					}
				end
			end
		end
	end

	return cities
end

-- Returns a list of the other living players' units that the player with ID playerID can see now:
-- each on a tile that is visible now, and seen by IsUnitVisible, which leaves out units such as a
-- stealthy one on a visible tile. A unit on a fogged tile is never listed. Unit IDs repeat across
-- players, so owner and id together name a unit. See UnitFlagManager.lua and MapSearchPanel.lua.
function SentientSystems_GetRivalUnitStates(playerID)
	local visibility = PlayersVisibility[playerID]
	local units = {}

	for _, player in ipairs(PlayerManager.GetAlive()) do
		local owner = player:GetID()

		if owner ~= playerID then
			for _, unit in player:GetUnits():Members() do
				if SentientSystems_IsUnitOnMap(unit) and visibility:IsVisible(unit:GetX(), unit:GetY()) and visibility:IsUnitVisible(unit) then
					units[#units + 1] = {
						owner = owner,
						id = unit:GetID(),
						type = GameInfo.Units[unit:GetType()].UnitType,
						x = unit:GetX(),
						y = unit:GetY(),
						health = { value = unit:GetMaxDamage() - unit:GetDamage(), max = unit:GetMaxDamage() },
					}
				end
			end
		end
	end

	return units
end
