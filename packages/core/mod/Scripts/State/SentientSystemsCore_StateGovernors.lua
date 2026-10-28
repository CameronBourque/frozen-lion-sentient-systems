-- The governors section of the state: the player's governor titles and each appointed governor, with
-- their city, how settled they are, their loyalty pressure, and their promotions, as the Governors
-- panel shows them. Rise and Fall adds governors, so without it the section is left out.
-- SentientSystemsCore_State.lua loads this file. Example: SentientSystems_GetGovernorState(player)
-- returns a table that encodes as '{"appointed":[{"city":{"id":393221,"owner":0},"established":true,
-- "loyalty":8,"name":"Reyna","promotions":["GOVERNOR_PROMOTION_MERCHANT_LAND_ACQUISITION"],
-- "title":"The Financier","turnsToEstablish":5,"type":"GOVERNOR_THE_MERCHANT"}],"spent":8,
-- "titles":1}', on one line. The checks follow Refresh and AddGovernorAppointed in GovernorPanel.lua,
-- and GetGovernorStatus in GovernorSupport.lua.

SentientSystems_Include("SentientSystemsCore_Governors")

-- Returns the promotions an appointed governor has, by type, in the order the panel lists them. See
-- AddGovernorAppointed in GovernorPanel.lua, lines 359 to 374.
local function GetPromotions(governor, definition)
	local promotions = {}

	for set in GameInfo.GovernorPromotionSets() do
		if set.GovernorType == definition.GovernorType then
			local promotion = GameInfo.GovernorPromotions[set.GovernorPromotion]

			if governor:HasPromotion(promotion.Hash) then
				promotions[#promotions + 1] = promotion.GovernorPromotionType
			end
		end
	end

	return promotions
end

-- Returns one appointed governor: type, name, title, city, with owner and id, left out while the
-- governor has none, established, whether they have settled in there, turnsLeft, the turns until
-- they do, neutralized, the turns they are out of action, there above 0 only, loyalty, the loyalty
-- pressure they give their city, turnsToEstablish, the turns they take to settle in a city, and
-- promotions. A Secret Society has secret, true, and neither loyalty nor turns, as its card shows no
-- stats. See GetGovernorStatus in GovernorSupport.lua, lines 72 to 95, AddGovernorInstance in
-- GovernorAssignmentChooser.lua, lines 103 to 121, and AddSecretGovernorAppointed in
-- GovernorPanel.lua, lines 313 to 350.
local function GetGovernor(governor)
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
		promotions = GetPromotions(governor, definition),
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

-- Returns the governors section: titles, the titles the player can still spend, spent, the titles
-- spent, and appointed, each appointed governor in the panel's order. Returns nil without Rise and
-- Fall, whose players have no GetGovernors. See Refresh in GovernorPanel.lua, lines 39 to 122.
function SentientSystems_GetGovernorState(player)
	if player.GetGovernors == nil then
		return nil
	end

	local governors = player:GetGovernors()
	local spent = governors:GetGovernorPointsSpent()
	local _, list = governors:GetGovernorList()
	local appointed = {}

	for i, governor in ipairs(list or {}) do
		appointed[i] = GetGovernor(governor)
	end

	return { titles = governors:GetGovernorPoints() - spent, spent = spent, appointed = appointed }
end
