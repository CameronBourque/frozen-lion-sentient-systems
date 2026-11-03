-- The great person choice: the great people the player can recruit or pass now, as the Great People
-- screen offers them. SentientSystemsCore_Choices.lua loads this file. The shape is in
-- bridge/src/choices/great-people.ts. The checks follow PopulateData and AddRecruit in
-- GreatPeoplePopup.lua.

-- Returns the great people the player can recruit or pass, in the screen's order. Returns nil when
-- there are none. See AddRecruit in GreatPeoplePopup.lua,
-- lines 265 to 287.
function SentientSystems_GetGreatPeopleChoices(player)
	local playerID = player:GetID()
	local greatPeople = Game.GetGreatPeople()
	local canRecruit = GameCapabilities.HasCapability("CAPABILITY_GREAT_PEOPLE_CAN_RECRUIT")
	local canPass = GameCapabilities.HasCapability("CAPABILITY_GREAT_PEOPLE_CAN_REJECT")
	local choices = {}

	for _, entry in ipairs(greatPeople:GetTimeline()) do
		if entry.Individual ~= nil then
			local recruit = canRecruit and greatPeople:CanRecruitPerson(playerID, entry.Individual)
			local pass = canPass and greatPeople:CanRejectPerson(playerID, entry.Individual)

			if recruit or pass then
				choices[#choices + 1] = {
					type = GameInfo.GreatPersonIndividuals[entry.Individual].GreatPersonIndividualType,
					recruit = recruit,
					passCost = pass and greatPeople:GetRejectCost(playerID, entry.Individual) or nil,
				}
			end
		end
	end

	return #choices > 0 and choices or nil
end
