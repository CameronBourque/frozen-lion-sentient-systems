-- The religion part of the victories section of the state: the religion a
-- player founded and the civs it has converted, as the Religion tab of World
-- Rankings shows them. SentientSystemsCore_StateVictories.lua loads this
-- file. Format: docs/findings/game-victories.md.

-- Returns the religion keys of a player's entry, none for a player with no
-- religion, whom the tab leaves out. A civ that the viewing player has not
-- met is counted but has no ID, as the tab shows only a question mark.
function SentientSystems_GetReligionDetails(player, other)
	local religion = other:GetReligion():GetReligionTypeCreated()

	if religion == -1 then
		return {}
	end

	local converted = {}
	local count = 0

	for _, rival in ipairs(PlayerManager.GetAliveMajors()) do
		if rival:GetReligion():GetReligionInMajorityOfCities() == religion then
			count = count + 1

			if SentientSystems_IsKnownPlayer(player, rival:GetID()) then
				converted[#converted + 1] = rival:GetID()
			end
		end
	end

	return {
		religion = GameInfo.Religions[religion].ReligionType,
		religionName = Game.GetReligion():GetName(religion),
		civsConverted = count,
		convertedCivs = #converted > 0 and converted or nil,
	}
end
