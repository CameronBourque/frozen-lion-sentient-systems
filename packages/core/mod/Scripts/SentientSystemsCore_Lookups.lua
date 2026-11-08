-- Lookups of the game's objects by the IDs the bridge sends, which the actions
-- and the placement share.

-- Returns the city of the player by ID, or nil and the reason. A number that is
-- no player has an object whose GetCities returns nothing.
function SentientSystems_FindCity(playerID, cityID)
	local player = Players[playerID]
	local cities = player and player:GetCities()
	local city = cities and cities:FindID(cityID)

	if city == nil then
		return nil, "Player " .. tostring(playerID) .. " has no city " .. tostring(cityID) .. "."
	end

	return city, nil
end
