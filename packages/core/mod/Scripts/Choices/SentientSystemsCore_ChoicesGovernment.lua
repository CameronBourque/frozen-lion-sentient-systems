-- The government and policy choices: the player's government, its policy slots, and the policy in
-- each slot, as the government screen's My Government tab shows them, the policies the player can
-- slot, as its policy catalog shows them, and every government, as its View Governments tab shows
-- them. SentientSystemsCore_Choices.lua loads this file.
-- Example: SentientSystems_GetGovernmentChoices(player) returns a table that encodes as
-- '{"slots":[{"slot":0,"type":"SLOT_MILITARY"},{"policy":"POLICY_GOD_KING","slot":1,
-- "type":"SLOT_ECONOMIC"}],"type":"GOVERNMENT_CHIEFDOM"}', and
-- SentientSystems_GetPolicyChoices(player) one that encodes as '{"canChange":false,"options":
-- {"SLOT_MILITARY":[{"description":"Double experience for recon units.","type":"POLICY_SURVEY"}]},
-- "unlock":{"cost":50,"yield":"YIELD_GOLD"}}', each on one line, and
-- SentientSystems_GetGovernmentOptions(player) one that encodes as '{"canChange":false,"options":
-- [{"current":true,"influence":{"envoys":1,"perTurn":1,"threshold":100},"slots":{"SLOT_ECONOMIC":1,
-- "SLOT_MILITARY":1},"type":"GOVERNMENT_CHIEFDOM"},...]}'. The checks follow
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

-- Returns whether the policy catalog shows a policy, active or not. See IsPolicyAvailable in
-- GovernmentScreen.lua, lines 2224 to 2229, and its replacement in GovernmentScreen_Expansion2.lua.
local function IsPolicyAvailable(culture, hash)
	if SentientSystems_HasExpansion2() then
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

-- Returns the button to pay to change policies and governments, as the screen shows it, or nil when
-- hidden is true or the cost is 0. blocked lists the screen's text when the player can't afford it,
-- and is empty while the World Congress is in session. See RealizeActivePoliciesRows in
-- GovernmentScreen.lua, lines 1380 to 1428, RealizeGovernmentsPage, lines 585 to 627, and
-- IsReadOnly in GovernmentScreen_Expansion2.lua.
local function GetUnlock(player, culture, hidden)
	local cost = culture:GetCostToUnlockPolicies()

	if hidden or cost == 0 then
		return nil
	end

	local byFaith = GlobalParameters.GOVERNMENT_UNLOCK_WITH_FAITH ~= 0
	local unlock = { cost = cost, yield = byFaith and "YIELD_FAITH" or "YIELD_GOLD" }
	local balance = byFaith and player:GetReligion():GetFaithBalance() or player:GetTreasury():GetGoldBalance()

	if balance < cost then
		unlock.blocked = { Locale.Lookup(byFaith and "LOC_GOVT_NEED_FAITH" or "LOC_GOVT_NEED_GOLD", cost) }
	elseif SentientSystems_HasExpansion2() and Game.GetWorldCongress():IsInSession() then
		unlock.blocked = {}
	end

	return unlock
end

-- Returns the policy choice: canChange, whether the player can change policies now, unlock, the
-- button to pay to change them, which the policies tab hides after a policy change this turn, and
-- options, the policies the catalog shows, by slot type. A slot
-- takes a policy of its own type, and a wildcard slot takes any policy. See IsAbleToChangePolicies
-- in GovernmentScreen.lua, lines 842 to 853.
function SentientSystems_GetPolicyChoices(player)
	local culture = player:GetCulture()

	return {
		canChange = (culture:CivicCompletedThisTurn() or culture:GetNumPolicySlotsOpen() > 0)
			and Game.IsAllowStrategicCommands(player:GetID())
			and not culture:PolicyChangeMade(),
		unlock = GetUnlock(player, culture, culture:PolicyChangeMade()),
		options = GetPolicyOptions(culture),
	}
end

-- Returns the slot counts of a government by slot type, as its card shows them, or nil for none.
-- See PopulateStaticData in GovernmentScreen.lua, lines 2431 to 2445.
local function GetSlotCounts(governmentType)
	local counts = {}

	for row in GameInfo.Government_SlotCounts() do
		if row.GovernmentType == governmentType then
			counts[row.GovernmentSlotType] = (counts[row.GovernmentSlotType] or 0) + row.NumSlots
		end
	end

	-- The JSON encoder writes an empty table as a list, so no slots leaves them out.
	return next(counts) ~= nil and counts or nil
end

-- Returns the percent a government's legacy bonus starts at, as its card shows it: the Amount of
-- the government's modifier whose BonusType is the government's. See
-- GetGovernmentFlatBonusPreview in GovernmentScreen.lua, lines 2465 to 2505.
local function GetLegacyPercent(row)
	for modifier in GameInfo.GovernmentModifiers() do
		if modifier.GovernmentType == row.GovernmentType then
			local bonusType, amount

			for argument in GameInfo.ModifierArguments() do
				if argument.ModifierId == modifier.ModifierId then
					if argument.Name == "BonusType" then
						bonusType = argument.Value
					elseif argument.Name == "Amount" then
						amount = tonumber(argument.Value)
					end
				end
			end

			if bonusType == row.BonusType and amount ~= nil then
				return amount
			end
		end
	end

	return 0
end

-- Returns a government's diplomatic favor per turn, from Gathering Storm's Governments_XP2, or nil
-- without it. See GetGovernmentStatsText in GovernmentScreen_Expansion2.lua.
local function GetFavor(governmentType)
	if not SentientSystems_HasExpansion2() then
		return nil
	end

	for row in GameInfo.Governments_XP2() do
		if row.GovernmentType == governmentType then
			return row.Favor
		end
	end
end

-- Returns one government as its card on the View Governments tab shows it. bonuses is the card's
-- two bonus lines, left out for a government with no bonus, as the card hides them. legacyPercent
-- is there when the ruleset has legacy bonuses, which Rise and Fall and Gathering Storm remove.
-- anarchy is the turns of anarchy to switch to it, when above 0, and is left out for the current
-- government. locked is the civic that unlocks a locked government. See RealizeGovernmentInstance
-- in GovernmentScreen.lua, lines 646 to 805, and OnGovernmentSelected, lines 879 to 902.
local function GetGovernmentOption(culture, row, currentIndex)
	local option = {
		type = row.GovernmentType,
		slots = GetSlotCounts(row.GovernmentType),
		influence = {
			perTurn = row.InfluencePointsPerTurn,
			threshold = row.InfluencePointsThreshold,
			envoys = row.InfluenceTokensPerThreshold,
		},
		favor = GetFavor(row.GovernmentType),
	}

	if row.BonusType ~= nil and row.BonusType ~= "NO_GOVERNMENTBONUS" then
		option.bonuses = { Locale.Lookup(row.InherentBonusDesc), Locale.Lookup(row.AccumulatedBonusShortDesc) }

		if GameCapabilities.HasCapability("CAPABILITY_GOVERNMENTS_LEGACY_BONUSES") then
			option.legacyPercent = GetLegacyPercent(row)
		end
	end

	if row.Index == currentIndex then
		option.current = true
	elseif culture:GetAnarchyTurns(row.Index) > 0 then
		option.anarchy = culture:GetAnarchyTurns(row.Index)
	end

	if not culture:IsGovernmentUnlocked(row.Hash) then
		-- true for a locked government with no civic, such as one a scenario adds.
		option.locked = row.PrereqCivic or true
	end

	return option
end

-- Returns the government options: canChange, whether the player can change government now, unlock,
-- the button to pay to change it, which the tab shows only with a government in place and another
-- unlocked, and options, every government in the game's order. See IsAbleToChangeGovernment in
-- GovernmentScreen.lua, lines 859 to 873.
function SentientSystems_GetGovernmentOptions(player)
	local culture = player:GetCulture()
	local currentIndex = culture:GetCurrentGovernment()
	local options, unlocked = {}, 0

	for row in GameInfo.Governments() do
		options[#options + 1] = GetGovernmentOption(culture, row, currentIndex)

		if culture:IsGovernmentUnlocked(row.Hash) then
			unlocked = unlocked + 1
		end
	end

	return {
		canChange = culture:CanChangeGovernmentAtAll()
			and not culture:GovernmentChangeMade()
			and Game.IsAllowStrategicCommands(player:GetID())
			and (currentIndex == -1 or culture:CivicCompletedThisTurn()),
		unlock = GetUnlock(player, culture, culture:GovernmentChangeMade() or unlocked <= 1 or currentIndex == -1),
		options = options,
	}
end
