-- The continents section: the continents the player has revealed, as the
-- continents lens key lists them. A tile's continent is in the tiles section.
-- Shape: bridge/src/state/continents.ts.

-- Returns a list of the continents with a tile that the player has revealed,
-- each with its index, type, and name. The index is the one that a tile's
-- continent holds. See ShowContinentLensKey in ModalLensPanel.lua.
function SentientSystems_GetContinentStates()
	local continents = {}

	for _, index in ipairs(Map.GetContinentsInUse()) do
		if next(Map.GetVisibleContinentPlots(index)) ~= nil then
			local row = GameInfo.Continents[index]

			continents[#continents + 1] = {
				index = index,
				type = row.ContinentType,
				name = Locale.Lookup(row.Description),
			}
		end
	end

	return continents
end
