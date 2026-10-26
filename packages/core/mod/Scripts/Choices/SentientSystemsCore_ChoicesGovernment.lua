-- The government and policy choices: the player's government, its policy slots, and the policy in
-- each slot, as the government screen's My Government tab shows them, and the policies the player
-- can slot, as its policy catalog shows them. SentientSystemsCore_Choices.lua loads this file.
-- Example: SentientSystems_GetGovernmentChoices(player) returns a table that encodes as
-- '{"slots":[{"slot":0,"type":"SLOT_MILITARY"},{"policy":"POLICY_GOD_KING","slot":1,
-- "type":"SLOT_ECONOMIC"}],"type":"GOVERNMENT_CHIEFDOM"}', and
-- SentientSystems_GetPolicyChoices(player) one that encodes as '{"canChange":false,"options":
-- {"SLOT_MILITARY":[{"description":"Double experience for recon units.","type":"POLICY_SURVEY"}]},
-- "unlock":{"cost":50,"yield":"YIELD_GOLD"}}', each on one line. The checks follow
-- GovernmentScreen.lua and its replacements in DLC/Expansion1 and DLC/Expansion2. The dark age
-- policies that the Expansion1 screen marks as new at the start of an era aren't marked.

-- Returns the player's government, with type, its type, left out when the player has none, before
-- Code of Laws or in anarchy, and slots, each policy slot in the game's order. Each slot has slot,
-- its index, which the game's policy changes take, type, and policy, left out for an empty slot.
-- See PopulateLivePlayerData in GovernmentScreen.lua, lines 2250 to 2318.
function SentientSystems_GetGovernmentChoices(player)
	local culture = player:GetCulture()
	local governmentIndex = culture:GetCurrentGovernment()
	local slots = {}

	for i = 0, culture:GetNumPolicySlots() - 1 do
		local slot = { slot = i, type = GameInfo.GovernmentSlots[culture:GetSlotType(i)].GovernmentSlotType }
		local policyIndex = culture:GetSlotPolicy(i)

		if policyIndex ~= -1 then
			slot.policy = GameInfo.Policies[policyIndex].PolicyType
		end

		slots[#slots + 1] = slot
	end

	return {
		type = governmentIndex ~= -1 and GameInfo.Governments[governmentIndex].GovernmentType or nil,
		slots = slots,
	}
end

-- Gathering Storm replaces the screen with GovernmentScreen_Expansion2.lua, which reads its
-- government rows from Governments_XP2.
local function HasExpansion2()
	return GameInfo.Governments_XP2 ~= nil
end

-- Returns whether the policy catalog shows a policy, active or not. See IsPolicyAvailable in
-- GovernmentScreen.lua, lines 2224 to 2229, and its replacement in GovernmentScreen_Expansion2.lua.
local function IsPolicyAvailable(culture, hash)
	if HasExpansion2() then
		return not culture:IsPolicyBanned(hash) and culture:CanPolicyBeSlotted(hash) and not culture:IsPolicyObsolete(hash)
	end

	return culture:IsPolicyUnlocked(hash) and not culture:IsPolicyObsolete(hash)
end

-- Returns the policies the catalog shows, by slot type, each list in type order, as the catalog
-- sorts them, or nil for none. A slotted policy is left out, as the catalog leaves it out. new is true for one the
-- civic completed this turn unlocks. See RealizePolicyCatalog in GovernmentScreen.lua, lines 1057 to
-- 1119, and PopulateLivePlayerData, lines 2257 to 2276.
local function GetPolicyOptions(culture)
	local civicThisTurn = culture:CivicCompletedThisTurn() and GameInfo.Civics[culture:GetCivicCompletedThisTurn()]
	local options = {}

	for row in GameInfo.Policies() do
		if IsPolicyAvailable(culture, row.Hash) and not culture:IsPolicyActive(row.Hash) then
			local list = options[row.GovernmentSlotType] or {}
			local option = { type = row.PolicyType, description = Locale.Lookup(row.Description) }

			if civicThisTurn and civicThisTurn.CivicType == row.PrereqCivic then
				option.new = true
			end

			list[#list + 1] = option
			options[row.GovernmentSlotType] = list
		end
	end

	for _, list in pairs(options) do
		table.sort(list, function(a, b)
			return a.type < b.type
		end)
	end

	-- The JSON encoder writes an empty table as a list, so no policy at all leaves options out.
	return next(options) ~= nil and options or nil
end

-- Returns the button to pay to change policies, as the screen shows it, or nil when the screen
-- hides it: after a policy change this turn, or when the cost is 0. blocked lists the screen's text
-- when the player can't afford it, and is empty while the World Congress is in session. See
-- RealizeActivePoliciesRows in GovernmentScreen.lua, lines 1380 to 1428, and IsReadOnly in
-- GovernmentScreen_Expansion2.lua.
local function GetUnlock(player, culture)
	local cost = culture:GetCostToUnlockPolicies()

	if culture:PolicyChangeMade() or cost == 0 then
		return nil
	end

	local byFaith = GlobalParameters.GOVERNMENT_UNLOCK_WITH_FAITH ~= 0
	local unlock = { cost = cost, yield = byFaith and "YIELD_FAITH" or "YIELD_GOLD" }
	local balance = byFaith and player:GetReligion():GetFaithBalance() or player:GetTreasury():GetGoldBalance()

	if balance < cost then
		unlock.blocked = { Locale.Lookup(byFaith and "LOC_GOVT_NEED_FAITH" or "LOC_GOVT_NEED_GOLD", cost) }
	elseif HasExpansion2() and Game.GetWorldCongress():IsInSession() then
		unlock.blocked = {}
	end

	return unlock
end

-- Returns the policy choice: canChange, whether the player can change policies now, unlock, the
-- button to pay to change them, and options, the policies the catalog shows, by slot type. A slot
-- takes a policy of its own type, and a wildcard slot takes any policy. See IsAbleToChangePolicies
-- in GovernmentScreen.lua, lines 842 to 853.
function SentientSystems_GetPolicyChoices(player)
	local culture = player:GetCulture()

	return {
		canChange = (culture:CivicCompletedThisTurn() or culture:GetNumPolicySlotsOpen() > 0)
			and Game.IsAllowStrategicCommands(player:GetID())
			and not culture:PolicyChangeMade(),
		unlock = GetUnlock(player, culture),
		options = GetPolicyOptions(culture),
	}
end
