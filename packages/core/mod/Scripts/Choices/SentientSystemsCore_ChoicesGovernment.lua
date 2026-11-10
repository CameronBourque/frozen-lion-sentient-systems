-- The government and policy choices, as the government screen shows them.
-- Follows GovernmentScreen.lua and its replacements in DLC/Expansion1 and 2.
-- Shape: bridge/src/choices/government.ts.

SentientSystems_Include("SentientSystemsCore_Government")

-- Returns the player's government and its policy slots. See
-- PopulateLivePlayerData in GovernmentScreen.lua.
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

-- Returns the policies the catalog shows, by slot type, each list in type
-- order, as the catalog sorts them, or nil for none. A slotted policy is left
-- out, as the catalog leaves it out. See RealizePolicyCatalog in
-- GovernmentScreen.lua, and PopulateLivePlayerData.
local function GetPolicyOptions(culture)
	local civicThisTurn = culture:CivicCompletedThisTurn() and GameInfo.Civics[culture:GetCivicCompletedThisTurn()]
	local options = {}

	for row in GameInfo.Policies() do
		if SentientSystems_IsPolicyAvailable(culture, row.Hash) and not culture:IsPolicyActive(row.Hash) then
			local list = options[row.GovernmentSlotType] or {}
			local option = { type = row.PolicyType, description = SentientSystems_LookupText(row.Description) }

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

	-- The JSON encoder writes an empty table as a list, so no policy at all
	-- leaves options out.
	return next(options) ~= nil and options or nil
end

-- Returns the policy choice. The policies tab hides the unlock button after a
-- policy change this turn.
function SentientSystems_GetPolicyChoices(player)
	local culture = player:GetCulture()

	return {
		canChange = SentientSystems_GetPolicyChangeFailure(player:GetID(), culture) == nil,
		unlock = SentientSystems_GetUnlock(player, culture, culture:PolicyChangeMade()),
		options = GetPolicyOptions(culture),
	}
end

-- Returns the slot counts of a government by slot type, as its card shows them,
-- or nil for none. See PopulateStaticData in GovernmentScreen.lua.
local function GetSlotCounts(governmentType)
	local counts = {}

	for row in GameInfo.Government_SlotCounts() do
		if row.GovernmentType == governmentType then
			counts[row.GovernmentSlotType] = (counts[row.GovernmentSlotType] or 0) + row.NumSlots
		end
	end

	-- The JSON encoder writes an empty table as a list, so no slots leaves them
	-- out.
	return next(counts) ~= nil and counts or nil
end

-- Returns the percent a government's legacy bonus starts at, as its card shows
-- it: the Amount of the government's modifier whose BonusType is the
-- government's. See GetGovernmentFlatBonusPreview in GovernmentScreen.lua.
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

-- Returns a government's diplomatic favor per turn, from Gathering Storm's
-- Governments_XP2, or nil without it. See GetGovernmentStatsText in
-- GovernmentScreen_Expansion2.lua.
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

-- Returns one government as its card on the View Governments tab shows it. Rise
-- and Fall and Gathering Storm remove the legacy bonuses. See
-- RealizeGovernmentInstance in GovernmentScreen.lua, and OnGovernmentSelected.
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
		option.bonuses = { SentientSystems_LookupText(row.InherentBonusDesc), SentientSystems_LookupText(row.AccumulatedBonusShortDesc) }

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
		-- true for a locked government with no civic, which a scenario can add.
		option.locked = row.PrereqCivic or true
	end

	return option
end

-- Returns the government options, with the screen's rules for a change and for
-- the unlock from SentientSystemsCore_Government.lua.
function SentientSystems_GetGovernmentOptions(player)
	local culture = player:GetCulture()
	local currentIndex = culture:GetCurrentGovernment()
	local options = {}

	for row in GameInfo.Governments() do
		options[#options + 1] = GetGovernmentOption(culture, row, currentIndex)
	end

	return {
		canChange = SentientSystems_GetGovernmentChangeFailure(player:GetID(), culture) == nil,
		unlock = SentientSystems_GetUnlock(player, culture, SentientSystems_IsGovernmentUnlockHidden(culture)),
		options = options,
	}
end
