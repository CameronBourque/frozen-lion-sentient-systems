-- The city actions. SentientSystemsCore_Actions.lua loads this file. The calls
-- are in docs/findings/game-actions.md.

-- Orders a city to shoot at a tile in its range, and returns the result as
-- JSON. A city's shot is a city command, and the UI shows no war dialog for it.
function SentientSystems_CityAttack(playerID, cityID, x, y)
	return SentientSystems_RunAction("CityAttack", function()
		local player = Players[playerID]
		local city = player and player:GetCities():FindID(cityID)

		if city == nil then
			return "Player " .. playerID .. " has no city " .. cityID .. "."
		end

		if x == nil or y == nil or not Map.IsPlot(x, y) then
			return "That tile is off the map."
		end

		if not PlayersVisibility[playerID]:IsVisible(x, y) then
			return "You can't see that tile."
		end

		local R = CityCommandResults
		local parameters = { [UnitOperationTypes.PARAM_X] = x, [UnitOperationTypes.PARAM_Y] = y }
		local tiles = SentientSystems_GetTargetTiles(CityManager.GetCommandTargets(city, CityCommandTypes.RANGE_ATTACK, {}), R.PLOTS, R.MODIFIERS, R.MODIFIER_IS_TARGET)

		for _, tile in ipairs(tiles) do
			if tile.x == x and tile.y == y then
				if not CityManager.CanStartCommand(city, CityCommandTypes.RANGE_ATTACK, parameters) then
					return "The game won't start that attack."
				end

				CityManager.RequestCommand(city, CityCommandTypes.RANGE_ATTACK, parameters)

				return nil
			end
		end

		return SentientSystems_GetNotTargetReason(tiles)
	end)
end
