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

-- Returns whether the View Governments tab hides the unlock: after a change of
-- government this turn, with no government, or with one government unlocked.
-- See RealizeGovernmentsPage in GovernmentScreen.lua.
function SentientSystems_IsGovernmentUnlockHidden(culture)
	if culture:GovernmentChangeMade() or culture:GetCurrentGovernment() == -1 then
		return true
	end

	local unlocked = 0

	for row in GameInfo.Governments() do
		if culture:IsGovernmentUnlocked(row.Hash) then
			unlocked = unlocked + 1
		end
	end

	return unlocked <= 1
end

-- Returns why the screen lets the player change no government now, or nil
-- when it does. The game's own check is in the screen alone, so the choice and
-- the action follow it. See IsAbleToChangeGovernment in GovernmentScreen.lua.
function SentientSystems_GetGovernmentChangeFailure(playerID, culture)
	if not Game.IsAllowStrategicCommands(playerID) then
		return "You can't change governments while it isn't your turn."
	end

	if not culture:CanChangeGovernmentAtAll() then
		return "You can't change governments yet."
	end

	if culture:GovernmentChangeMade() then
		return "You changed governments this turn already."
	end

	if culture:GetCurrentGovernment() == -1 or culture:CivicCompletedThisTurn() then
		return nil
	end

	local reason = "You can change governments only on a turn you complete a civic."

	if culture:GetCostToUnlockPolicies() > 0 and not SentientSystems_IsGovernmentUnlockHidden(culture) then
		reason = reason .. " The governments choice's unlock pays for a change now."
	end

	return reason
end

-- Returns the button to pay to change policies and governments, as the screen
-- shows it, or nil when hidden is true or the cost is 0. blocked lists the
-- screen's text when the player can't afford it, and is empty while the World
-- Congress is in session. See RealizeActivePoliciesRows in
-- GovernmentScreen.lua, RealizeGovernmentsPage, and IsReadOnly in
-- GovernmentScreen_Expansion2.lua.
function SentientSystems_GetUnlock(player, culture, hidden)
	local cost = culture:GetCostToUnlockPolicies()

	if hidden or cost == 0 then
		return nil
	end

	local byFaith = GlobalParameters.GOVERNMENT_UNLOCK_WITH_FAITH ~= 0
	local unlock = { cost = cost, yield = byFaith and "YIELD_FAITH" or "YIELD_GOLD" }
	local balance = byFaith and player:GetReligion():GetFaithBalance() or player:GetTreasury():GetGoldBalance()

	if balance < cost then
		unlock.blocked = { SentientSystems_LookupText(byFaith and "LOC_GOVT_NEED_FAITH" or "LOC_GOVT_NEED_GOLD", cost) }
	elseif SentientSystems_HasExpansion2() and Game.GetWorldCongress():IsInSession() then
		unlock.blocked = {}
	end

	return unlock
end
