-- The rivals section: other players' cities and units the player can know
-- about. Loads after cities and units. See
-- docs/findings/state/tile-visibility.md. Shape: bridge/src/state/rivals.ts.

-- Returns a list of the other living players' cities on tiles that the player
-- with ID playerID has revealed. A city's banner shows on a revealed tile,
-- fogged or not. City IDs repeat across players, so owner and id together name
-- a city.
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

-- Returns a list of the other living players' units that the player with ID
-- playerID can see now: each on a tile that is visible now, and seen by
-- IsUnitVisible, which leaves out a stealthy unit on a visible tile. A unit on
-- a fogged tile is never listed. Unit IDs repeat across players, so owner and
-- id together name a unit. A religious unit has its religion, as its flag shows
-- it, and its religious strength. See UnitFlagManager.lua and
-- MapSearchPanel.lua.
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
						health = SentientSystems_GetHealth(unit:GetMaxDamage(), unit:GetDamage()),
						religion = SentientSystems_GetUnitReligion(unit),
						religiousStrength = SentientSystems_GetReligiousStrength(unit),
					}
				end
			end
		end
	end

	return units
end
