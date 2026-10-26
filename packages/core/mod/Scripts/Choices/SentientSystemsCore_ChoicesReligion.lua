-- The religion choices: the pantheon beliefs the player can found a pantheon with, as the pantheon
-- chooser lists them. SentientSystemsCore_Choices.lua loads this file. Example:
-- SentientSystems_GetPantheonChoices(player) returns a table that encodes as
-- '{"beliefs":[{"description":"Holy Site districts get +1 [ICON_Faith] Faith from adjacent Tundra
-- tiles.","type":"BELIEF_DANCE_OF_THE_AURORA"},...]}', on one line. The checks follow
-- PantheonChooser.lua.

-- Returns the pantheon choice, with beliefs, the pantheon beliefs no player has taken, in the
-- game's order, each with its type and description. Returns nil unless the player can found a
-- pantheon now, as the launch bar opens the chooser only then. See Realize and CanSelectBelief in
-- PantheonChooser.lua, lines 23 to 72, and LaunchBar.lua, lines 136 to 140.
function SentientSystems_GetPantheonChoices(player)
	local religion = player:GetReligion()

	if religion:GetPantheon() >= 0 or not religion:CanCreatePantheon() then
		return nil
	end

	local gameReligion = Game.GetReligion()
	local beliefs = {}

	for row in GameInfo.Beliefs() do
		if row.BeliefClassType == "BELIEF_CLASS_PANTHEON"
			and not gameReligion:IsInSomePantheon(row.Index)
			and not gameReligion:IsInSomeReligion(row.Index)
		then
			beliefs[#beliefs + 1] = { type = row.BeliefType, description = Locale.Lookup(row.Description) }
		end
	end

	return { beliefs = beliefs }
end
