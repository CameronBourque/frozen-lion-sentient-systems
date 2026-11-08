-- Lookups of the game's objects by the IDs the bridge sends, which the state,
-- the choices, the actions, the placement, and the trees share.

-- Returns the player by ID. Raises an error for an ID with no player.
function SentientSystems_GetPlayer(playerID)
	local player = Players[playerID]

	if player == nil then
		error("no player " .. tostring(playerID), 0)
	end

	return player
end

-- Returns a city's owner, ID, and name, the reference the bridge sends back to
-- name it, or nil with no city.
function SentientSystems_GetCityRef(city)
	if city == nil then
		return nil
	end

	return { owner = city:GetOwner(), id = city:GetID(), name = Locale.Lookup(city:GetName()) }
end

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
