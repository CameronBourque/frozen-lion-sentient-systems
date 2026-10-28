-- Builds one player's governor tree as JSON for the bridge, in a call of its own, as the Governors
-- panel and its details panel show it, so the agent can choose which governor to appoint and which
-- promotion to give. It reads the tree from the running game. Rise and Fall adds governors, so
-- without it the tree is empty. See docs/design/core/in-game-lua.md. Example:
-- SentientSystems_GetGovernorTree(0) returns '{"governors":[{"description":"Shrewd and fiscally
-- knowledgeable, ...","loyalty":8,"name":"Reyna","promotions":[{"column":1,"description":"...",
-- "level":0,"name":"Land Acquisition","requires":[],"status":"held","type":
-- "GOVERNOR_PROMOTION_MERCHANT_LAND_ACQUISITION"},...],"status":"appointed","title":"The Financier",
-- "turnsToEstablish":5,"type":"GOVERNOR_THE_MERCHANT"},...]}', on one line. The checks follow Refresh
-- and AddGovernorCandidate in GovernorPanel.lua, and CreatePromotionTree in GovernorDetailsPanel.lua.

include("SentientSystemsCore_Common")
SentientSystems_Include("SentientSystemsCore_Json")
SentientSystems_Include("SentientSystemsCore_Governors")

-- Returns the promotions each promotion follows, by type, from GameInfo.GovernorPromotionPrereqs. A
-- promotion needs any one of them, as the game allows Tax Collector with only Harbormaster.
local function GetPrerequisites()
	local prerequisites = {}

	for row in GameInfo.GovernorPromotionPrereqs() do
		local list = prerequisites[row.GovernorPromotionType] or {}

		list[#list + 1] = row.PrereqGovernorPromotion
		prerequisites[row.GovernorPromotionType] = list
	end

	return prerequisites
end

-- Returns the promotions of a governor, in the game's order, each with type, name,
-- description, level, column, requires, the promotions it follows, any one of which it needs, and
-- status: held, for one the governor has, available, for one they can earn now, and locked, for one
-- that needs a prerequisite first. A promotion the panel hides has hidden, true, and the game's own
-- text in place of its name and description. A governor of nil is a candidate, whose card shows only
-- the base ability as held. See CreatePromotionTree in GovernorDetailsPanel.lua, lines 150 to 230,
-- CreateSecretPromotionTree, lines 270 to 328, and AddGovernorCandidate in GovernorPanel.lua, lines
-- 198 to 207.
local function GetPromotions(governors, governor, definition, prerequisites)
	local promotions = {}

	for set in GameInfo.GovernorPromotionSets() do
		if set.GovernorType == definition.GovernorType then
			local promotion = GameInfo.GovernorPromotions[set.GovernorPromotion]
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
	end

	return promotions
end

-- Returns one governor with their tree: type, name, title, description, status, appointed or
-- candidate, turnsToEstablish, the turns they take to settle in a city, loyalty, the loyalty pressure
-- they give, and promotions. A Secret Society has secret, true, and neither turns nor loyalty, as its
-- card shows no stats.
local function GetGovernor(governors, governor, definition, prerequisites)
	local secret = SentientSystems_IsCannotAssign(definition)

	return {
		type = definition.GovernorType,
		name = Locale.Lookup(definition.Name),
		title = Locale.Lookup(definition.Title),
		description = Locale.Lookup(definition.Description),
		status = governor and "appointed" or "candidate",
		secret = secret and true or nil,
		turnsToEstablish = not secret and (governor and governor:GetTurnsToEstablish() or governors:GetTurnsToEstablish(definition.Hash)) or nil,
		loyalty = not secret and (governor and governor:GetIdentityPressure() or definition.IdentityPressure) or nil,
		promotions = GetPromotions(governors, governor, definition, prerequisites),
	}
end

-- Returns the governor tree of the player with ID playerID as JSON: each appointed governor in the
-- panel's order, then each governor the player could still appoint, which includes the Secret
-- Societies they have discovered. Raises an error for an ID with
-- no player. The bridge reads it through the stash, as
-- SentientSystems_Stash(SentientSystems_GetGovernorTree(playerID)). See Refresh in GovernorPanel.lua,
-- lines 39 to 122.
function SentientSystems_GetGovernorTree(playerID)
	local player = Players[playerID]

	if player == nil then
		error("no player " .. tostring(playerID), 0)
	end

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
