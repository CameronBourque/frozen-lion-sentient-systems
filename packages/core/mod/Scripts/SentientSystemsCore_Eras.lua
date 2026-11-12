-- The age rules that the era state, the dedication choice, and the dedication
-- action share: a player's age, the dedication waiting, and its bonus text.
-- Follows EraProgressPanel.lua and DedicationPopup.lua.

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

-- Returns the dedication waiting for the player: the eras, how many to pick,
-- the age, and the offered rows of GameInfo.CommemorationTypes. Returns nil
-- with none to make. It reads the era's choices only while the blocker is up,
-- as the popup does, since a call with nothing waiting crashed the game for
-- spies. See OnGameEraChanged in DedicationPopup.lua.
function SentientSystems_GetPendingDedication(player)
	local playerID = player:GetID()

	if not SentientSystems_HasBlocker(playerID, "ENDTURN_BLOCKING_COMMEMORATION_AVAILABLE") then
		return nil
	end

	local eras = Game.GetEras()
	local picks = eras:GetPlayerNumAllowedCommemorations(playerID)
	local rows = {}

	for _, index in ipairs(eras:GetPlayerCommemorateChoices(playerID)) do
		rows[#rows + 1] = GameInfo.CommemorationTypes[index]
	end

	if picks <= 0 or #rows == 0 then
		return nil
	end

	return { eras = eras, picks = picks, age = SentientSystems_GetAge(eras, playerID), rows = rows }
end
