-- The rules about governors that the state, the choice, and the tree share: which governors are
-- Secret Societies, which of their promotions the Governors panel hides, and the text it shows in
-- their place. SentientSystemsCore_StateGovernors.lua, SentientSystemsCore_ChoicesGovernors.lua, and
-- SentientSystemsCore_TreesGovernors.lua load this file. The checks follow GovernorSupport.lua.

include("SentientSystemsCore_Common")

-- The name and description the game shows for a promotion that is still hidden.
local HIDDEN_NAME_KEY = "LOC_GOVERNOR_PROMOTION_UNKNOWN_NAME"
local HIDDEN_DESCRIPTION_KEY = "LOC_GOVERNOR_PROMOTION_UNKNOWN_DESCRIPTION"

-- Returns whether a governor can't be assigned to a city, which only a Secret Society can't. The panel
-- shows such a governor as a society, with no stats and no Assign button. See IsCannotAssign in
-- GovernorSupport.lua, lines 110 to 125.
function SentientSystems_IsCannotAssign(definition)
	if GameInfo.GovernorsCannotAssign ~= nil then
		for row in GameInfo.GovernorsCannotAssign() do
			if row.GovernorType == definition.GovernorType then
				return row.CannotAssign
			end
		end
	end

	return false
end

-- Returns whether the panel hides a promotion: its row in GameInfo.GovernorPromotionConditions says
-- HiddenWithoutPrereqs, and the governor doesn't hold every promotion it follows. Without an
-- appointed governor, such as a candidate, it is hidden. See IsPromotionHidden and
-- HasPromotionPrerequisites in GovernorSupport.lua, lines 127 to 183.
function SentientSystems_IsPromotionHidden(promotion, governor)
	local hiddenWithoutPrerequisites = false

	if GameInfo.GovernorPromotionConditions ~= nil then
		for row in GameInfo.GovernorPromotionConditions() do
			if row.GovernorPromotionType == promotion.GovernorPromotionType then
				hiddenWithoutPrerequisites = row.HiddenWithoutPrereqs
			end
		end
	end

	if not hiddenWithoutPrerequisites then
		return false
	end

	if governor == nil then
		return true
	end

	for row in GameInfo.GovernorPromotionPrereqs() do
		if row.GovernorPromotionType == promotion.GovernorPromotionType then
			local prerequisite = GameInfo.GovernorPromotions[row.PrereqGovernorPromotion]

			if prerequisite ~= nil and not governor:HasPromotion(prerequisite.Hash) then
				return true
			end
		end
	end

	return false
end

-- Returns a promotion's name and description as the panel shows them, and true as the third value
-- when it hides them: the game's own text for an unknown promotion, or ? when it has none. The
-- governor is the appointed one, or nil for a candidate. See GetPromotionHiddenName and
-- GetPromotionHiddenDescription in GovernorSupport.lua, lines 149 to 165.
function SentientSystems_GetPromotionTexts(promotion, governor)
	if not SentientSystems_IsPromotionHidden(promotion, governor) then
		return Locale.Lookup(promotion.Name), Locale.Lookup(promotion.Description), nil
	end

	local name = Locale.Lookup(HIDDEN_NAME_KEY)
	local description = Locale.Lookup(HIDDEN_DESCRIPTION_KEY)

	return name ~= HIDDEN_NAME_KEY and name or "?", description ~= HIDDEN_DESCRIPTION_KEY and description or "?", true
end
