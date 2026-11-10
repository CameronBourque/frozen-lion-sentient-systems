-- The government screen's rules that the government choices and the policy
-- actions share. Follows GovernmentScreen.lua.

include("SentientSystemsCore_Common")

-- Returns whether the policy catalog shows a policy, active or not. See
-- IsPolicyAvailable in GovernmentScreen.lua, and its replacement in
-- GovernmentScreen_Expansion2.lua.
function SentientSystems_IsPolicyAvailable(culture, hash)
	if SentientSystems_HasExpansion2() then
		return not culture:IsPolicyBanned(hash) and culture:CanPolicyBeSlotted(hash) and not culture:IsPolicyObsolete(hash)
	end

	return culture:IsPolicyUnlocked(hash) and not culture:IsPolicyObsolete(hash)
end

-- Returns why the screen lets the player change no policy now, or nil when it
-- does. The game takes a change at any time, so the choice and the actions
-- follow the screen. See IsAbleToChangePolicies in GovernmentScreen.lua.
function SentientSystems_GetPolicyChangeFailure(playerID, culture)
	if not Game.IsAllowStrategicCommands(playerID) then
		return "You can't change policies while it isn't your turn."
	end

	if culture:PolicyChangeMade() then
		return "You changed policies this turn already."
	end

	if culture:CivicCompletedThisTurn() or culture:GetNumPolicySlotsOpen() > 0 then
		return nil
	end

	local reason = "You can change policies only on a turn you complete a civic, or while a slot is empty."

	if culture:GetCostToUnlockPolicies() > 0 then
		reason = reason .. " The policies choice's unlock pays for a change now."
	end

	return reason
end
