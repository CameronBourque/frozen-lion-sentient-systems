-- Builds one player's governor tree as JSON, as the Governors panel shows it.
-- Needs Rise and Fall. Follows Refresh and AddGovernorCandidate in
-- GovernorPanel.lua. Shape: bridge/src/trees/governors.ts.

include("SentientSystemsCore_Common")
SentientSystems_Include("SentientSystemsCore_Json")
SentientSystems_Include("SentientSystemsCore_Lookups")
SentientSystems_Include("SentientSystemsCore_Governors")

-- Returns the promotions each promotion follows, by type, from
-- GameInfo.GovernorPromotionPrereqs. A promotion needs any one of them, as the
-- game allows Tax Collector with only Harbormaster.
local function GetPrerequisites()
	local prerequisites = {}

	for row in GameInfo.GovernorPromotionPrereqs() do
		local list = prerequisites[row.GovernorPromotionType] or {}

		list[#list + 1] = row.PrereqGovernorPromotion
		prerequisites[row.GovernorPromotionType] = list
	end

	return prerequisites
end

-- Returns the promotions of a governor, in the game's order. A governor of nil
-- is a candidate, whose card shows only the base ability as held. See
-- CreatePromotionTree in GovernorDetailsPanel.lua, CreateSecretPromotionTree,
-- and AddGovernorCandidate in GovernorPanel.lua.
local function GetPromotions(governors, governor, definition, prerequisites)
	local promotions = {}

	for _, promotion in ipairs(SentientSystems_GetPromotionRows(definition)) do
		local status = "locked"

		if governor == nil and promotion.BaseAbility or governor ~= nil and governor:HasPromotion(promotion.Hash) then
			status = "held"
		elseif governor ~= nil and governors:CanEarnPromotion(definition.Hash, promotion.Hash) then
			status = "available"
		end

		local name, description, hidden = SentientSystems_GetPromotionTexts(promotion, governor)

		promotions[#promotions + 1] = {
			type = promotion.GovernorPromotionType,
			name = name,
			description = description,
			hidden = hidden,
			level = promotion.Level,
			column = promotion.Column,
			requires = prerequisites[promotion.GovernorPromotionType] or {},
			status = status,
		}
	end

	return promotions
end

-- Returns one governor with their tree. A Secret Society has neither turns nor
-- loyalty, as its card shows no stats.
local function GetGovernor(governors, governor, definition, prerequisites)
	local secret = SentientSystems_IsCannotAssign(definition)

	return {
		type = definition.GovernorType,
		name = Locale.Lookup(definition.Name),
		title = Locale.Lookup(definition.Title),
		description = SentientSystems_LookupText(definition.Description),
		status = governor and "appointed" or "candidate",
		secret = secret and true or nil,
		turnsToEstablish = not secret and (governor and governor:GetTurnsToEstablish() or governors:GetTurnsToEstablish(definition.Hash)) or nil,
		loyalty = not secret and (governor and governor:GetIdentityPressure() or definition.IdentityPressure) or nil,
		promotions = GetPromotions(governors, governor, definition, prerequisites),
	}
end

-- Returns the governor tree of the player with ID playerID as JSON. Raises an
-- error for an ID with no player. The bridge reads it through the stash, as
-- SentientSystems_Stash(SentientSystems_GetGovernorTree(playerID)). See Refresh
-- in GovernorPanel.lua.
function SentientSystems_GetGovernorTree(playerID)
	local player = SentientSystems_GetPlayer(playerID)

	local entries = {}

	if player.GetGovernors ~= nil then
		local governors = player:GetGovernors()
		local prerequisites = GetPrerequisites()
		local _, appointed = governors:GetGovernorList()

		for _, governor in ipairs(appointed or {}) do
			entries[#entries + 1] = GetGovernor(governors, governor, GameInfo.Governors[governor:GetType()], prerequisites)
		end

		for definition in GameInfo.Governors() do
			local hash = definition.Hash

			if not governors:HasGovernor(hash) and governors:CanEverAppointGovernor(hash) then
				entries[#entries + 1] = GetGovernor(governors, nil, definition, prerequisites)
			end
		end
	end

	return SentientSystems_EncodeJson({ governors = entries })
end
