-- The age rules that the era state and the dedication choice share: which age
-- a player is in, and a dedication's bonus text. Follows EraProgressPanel.lua
-- and DedicationPopup.lua.

include("SentientSystemsCore_Common")
SentientSystems_Include("SentientSystemsCore_Text")

-- Returns the player's age, heroic, golden, dark, or normal, as the panels
-- decide it: heroic before golden, and golden before dark.
function SentientSystems_GetAge(eras, playerID)
	if eras:HasHeroicGoldenAge(playerID) then
		return "heroic"
	elseif eras:HasGoldenAge(playerID) then
		return "golden"
	elseif eras:HasDarkAge(playerID) then
		return "dark"
	end

	return "normal"
end

-- Returns the text of a dedication for the age: the golden text, with the
-- normal text after it for a player always allowed the normal bonus, in a
-- golden age, the dark text in a dark age, and the normal text otherwise. A
-- heroic age counts as golden.
function SentientSystems_GetDedicationText(eras, playerID, row, age)
	if age == "heroic" or age == "golden" then
		local text = SentientSystems_LookupText(row.GoldenAgeBonusDescription)

		if eras:IsPlayerAlwaysAllowedCommemorationQuest(playerID) then
			text = text .. "\n" .. SentientSystems_LookupText(row.NormalAgeBonusDescription)
		end

		return text
	elseif age == "dark" then
		return SentientSystems_LookupText(row.DarkAgeBonusDescription)
	end

	return SentientSystems_LookupText(row.NormalAgeBonusDescription)
end
