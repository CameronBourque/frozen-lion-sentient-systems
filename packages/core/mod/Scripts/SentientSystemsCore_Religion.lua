-- The religion rules that the religion choices and the religion actions share.
-- Follows PantheonChooser.lua and ReligionScreen.lua.

-- Returns whether a player's pantheon or religion holds the belief, so no other
-- player can take it. See CanSelectBelief in PantheonChooser.lua.
function SentientSystems_IsBeliefTaken(gameReligion, index)
	return gameReligion:IsInSomePantheon(index) or gameReligion:IsInSomeReligion(index)
end
