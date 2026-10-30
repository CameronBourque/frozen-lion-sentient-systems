-- The domination part of the victories section of the state: the original
-- capitals a player holds, as the Domination tab of World Rankings shows
-- them. SentientSystemsCore_StateVictories.lua loads this file. Format:
-- docs/findings/game-victories.md.

-- Returns the domination keys of a player's entry, none for a player with no
-- capital, whom the tab leaves out. An owner that the viewing player has not
-- met is counted but has no ID, as the tab shows only a question mark.
function SentientSystems_GetDominationDetails(player, other)
	if other:GetCities():GetCapitalCity() == nil then
		return {}
	end

	local id = other:GetID()
	local details = { hasOriginalCapital = false, capitalsCaptured = 0 }
	local captured = {}

	for _, city in other:GetCities():Members() do
		local owner = city:GetOriginalOwner()

		if city:IsOriginalCapital() and Players[owner]:IsMajor() then
			if owner == id then
				details.hasOriginalCapital = true
			else
				details.capitalsCaptured = details.capitalsCaptured + 1

				if SentientSystems_IsKnownPlayer(player, owner) then
					captured[#captured + 1] = owner
				end
			end
		end
	end

	details.capturedCapitals = #captured > 0 and captured or nil

	return details
end
