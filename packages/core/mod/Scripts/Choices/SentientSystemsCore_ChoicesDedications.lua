-- The dedication choice: the dedications the player may make for the era that began, as the
-- dedication popup offers them. SentientSystemsCore_Choices.lua loads this file. The shape is in
-- bridge/src/choices/dedications.ts. The checks follow OnGameEraChanged and CreateCommemoration in
-- DedicationPopup.lua.

SentientSystems_Include("SentientSystemsCore_Eras")

-- Returns the dedication choice. Returns nil with no dedication to make. The calls read the era's choices only while the blocker is
-- up, as the spy choice must. See DedicationPopup.lua, lines 25 to 120.
function SentientSystems_GetDedicationChoices(player)
	local playerID = player:GetID()

	if not SentientSystems_HasBlocker(playerID, "ENDTURN_BLOCKING_COMMEMORATION_AVAILABLE") then
		return nil
	end

	local eras = Game.GetEras()
	local picks = eras:GetPlayerNumAllowedCommemorations(playerID)
	local age = SentientSystems_GetAge(eras, playerID)
	local options = {}

	for _, index in ipairs(eras:GetPlayerCommemorateChoices(playerID)) do
		local row = GameInfo.CommemorationTypes[index]

		options[#options + 1] = {
			type = row.CommemorationType,
			name = Locale.Lookup(row.CategoryDescription),
			description = SentientSystems_GetDedicationText(eras, playerID, row, age),
		}
	end

	if picks <= 0 or #options == 0 then
		return nil
	end

	return {
		era = Locale.Lookup(GameInfo.Eras[eras:GetCurrentEra()].Name),
		age = age,
		picks = picks,
		options = options,
	}
end
