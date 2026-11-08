-- The governors section, as the Governors panel shows it. Follows Refresh and
-- AddGovernorAppointed in GovernorPanel.lua, GetGovernorStatus in
-- GovernorSupport.lua. Shape: bridge/src/state/governors.ts.

SentientSystems_Include("SentientSystemsCore_Governors")

-- Returns the promotions an appointed governor has, by type, in the order the
-- panel lists them. See AddGovernorAppointed in GovernorPanel.lua.
local function GetHeldPromotions(governor, definition)
	local promotions = {}

	for _, promotion in ipairs(SentientSystems_GetPromotionRows(definition)) do
		if governor:HasPromotion(promotion.Hash) then
			promotions[#promotions + 1] = promotion.GovernorPromotionType
		end
	end

	return promotions
end

-- Returns one appointed governor. A Secret Society has neither loyalty nor
-- turns, as its card shows no stats. See GetGovernorStatus in
-- GovernorSupport.lua, AddGovernorInstance in GovernorAssignmentChooser.lua,
-- and AddSecretGovernorAppointed in GovernorPanel.lua.
local function GetAppointedGovernor(governor)
	local definition = GameInfo.Governors[governor:GetType()]
	local city = governor:GetAssignedCity()
	local neutralized = governor:GetNeutralizedTurns()
	local secret = SentientSystems_IsCannotAssign(definition)
	local entry = {
		type = definition.GovernorType,
		name = Locale.Lookup(definition.Name),
		title = Locale.Lookup(definition.Title),
		secret = secret and true or nil,
		neutralized = neutralized > 0 and neutralized or nil,
		loyalty = not secret and governor:GetIdentityPressure() or nil,
		turnsToEstablish = not secret and governor:GetTurnsToEstablish() or nil,
		promotions = GetHeldPromotions(governor, definition),
	}

	if city ~= nil then
		entry.city = { owner = city:GetOwner(), id = city:GetID() }
		entry.established = governor:IsEstablished()

		if not entry.established then
			entry.turnsLeft = governor:GetTurnsToEstablish() - governor:GetTurnsOnSite()
		end
	end

	return entry
end

-- Returns the governors section, or nil without Rise and Fall, whose players
-- have no GetGovernors. See Refresh in GovernorPanel.lua.
function SentientSystems_GetGovernorState(player)
	if player.GetGovernors == nil then
		return nil
	end

	local governors = player:GetGovernors()
	local spent = governors:GetGovernorPointsSpent()
	local _, list = governors:GetGovernorList()
	local appointed = {}

	for i, governor in ipairs(list or {}) do
		appointed[i] = GetAppointedGovernor(governor)
	end

	return { titles = governors:GetGovernorPoints() - spent, spent = spent, appointed = appointed }
end
