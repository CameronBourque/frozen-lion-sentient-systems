-- The religion rules that the religion choices and the religion actions share.
-- Follows PantheonChooser.lua and ReligionScreen.lua.

-- Returns whether a player's pantheon or religion holds the belief, so no other
-- player can take it. See CanSelectBelief in PantheonChooser.lua.
function SentientSystems_IsBeliefTaken(gameReligion, index)
	return gameReligion:IsInSomePantheon(index) or gameReligion:IsInSomeReligion(index)
end

-- Returns the beliefs the founder of a religion has added to it, or none before
-- they found one.
local function CountBeliefs(playerID)
	for _, entry in ipairs(Game.GetReligion():GetReligions()) do
		if entry.Founder == playerID then
			return #entry.Beliefs
		end
	end

	return 0
end

-- Returns how many beliefs the player can pick now: those earned, from a Great
-- Prophet or an Apostle, less those their religion has. See ViewMyReligion in
-- ReligionScreen.lua.
function SentientSystems_GetBeliefPicks(player)
	return player:GetReligion():GetNumBeliefsEarned() - CountBeliefs(player:GetID())
end
