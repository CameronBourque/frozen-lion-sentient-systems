-- The governor rules that the state, the choice, the tree, and the actions
-- share: Secret Societies, promotions, what the panel hides, and what its
-- buttons allow. Follows GovernorSupport.lua and GovernorPanel.lua.

include("SentientSystemsCore_Common")
SentientSystems_Include("SentientSystemsCore_Text")

-- The name and description the game shows for a promotion that is still hidden.
local HIDDEN_NAME_KEY = "LOC_GOVERNOR_PROMOTION_UNKNOWN_NAME"
local HIDDEN_DESCRIPTION_KEY = "LOC_GOVERNOR_PROMOTION_UNKNOWN_DESCRIPTION"

-- Returns the GameInfo.GovernorPromotions rows of a governor, in the order of
-- GameInfo.GovernorPromotionSets. See CreatePromotionTree in
-- GovernorDetailsPanel.lua.
function SentientSystems_GetPromotionRows(definition)
	local rows = {}

	for set in GameInfo.GovernorPromotionSets() do
		if set.GovernorType == definition.GovernorType then
			rows[#rows + 1] = GameInfo.GovernorPromotions[set.GovernorPromotion]
		end
	end

	return rows
end

-- Returns whether a governor can't be assigned to a city, which only a Secret
-- Society can't. The panel shows such a governor as a society, with no stats
-- and no Assign button. See IsCannotAssign in GovernorSupport.lua.
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

-- Returns whether the panel hides a promotion: its row in
-- GameInfo.GovernorPromotionConditions says HiddenWithoutPrereqs, and the
-- governor doesn't hold every promotion it follows. Without an appointed
-- governor it is hidden. See IsPromotionHidden and HasPromotionPrerequisites in
-- GovernorSupport.lua.
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

-- Returns a promotion's name and description as the panel shows them, and true
-- as the third value when it hides them: the game's own text for an unknown
-- promotion, or ? when it has none. The governor is the appointed one, or nil
-- for a candidate. See GetPromotionHiddenName and GetPromotionHiddenDescription
-- in GovernorSupport.lua.
function SentientSystems_GetPromotionTexts(promotion, governor)
	if not SentientSystems_IsPromotionHidden(promotion, governor) then
		return Locale.Lookup(promotion.Name), SentientSystems_LookupText(promotion.Description), nil
	end

	local name = Locale.Lookup(HIDDEN_NAME_KEY)
	local description = Locale.Lookup(HIDDEN_DESCRIPTION_KEY)

	return name ~= HIDDEN_NAME_KEY and name or "?", description ~= HIDDEN_DESCRIPTION_KEY and SentientSystems_CleanText(description) or "?", true
end

-- Returns why the Governors panel is closed to the player, or nil: a game
-- without Rise and Fall, or Gathering Storm's World Congress in session, which
-- turns every button off. See Refresh in GovernorPanel.lua, and IsReadOnly.
function SentientSystems_GetGovernorsClosedReason(player)
	if player.GetGovernors == nil then
		return "This game has no governors. They come with Rise and Fall."
	end

	if SentientSystems_HasExpansion2() and Game.GetWorldCongress():IsInSession() then
		return "The World Congress is in session. Act on governors after it ends."
	end

	return nil
end

-- Returns whether the panel shows an Appoint button for a governor the player
-- hasn't appointed. It turns the button off without a title to spend. See
-- Refresh in GovernorPanel.lua.
function SentientSystems_IsAppointable(governors, definition)
	return not governors:HasGovernor(definition.Hash) and governors:CanEverAppointGovernor(definition.Hash)
end

-- Returns whether an appointed governor can earn a promotion now. See
-- CreatePromotionTree in GovernorDetailsPanel.lua.
function SentientSystems_IsPromotionEarnable(governors, governor, definition, promotion)
	return not governor:HasPromotion(promotion.Hash) and governors:CanEarnPromotion(definition.Hash, promotion.Hash)
end

-- Returns whether the panel turns a governor's Assign button on: not for a
-- Secret Society, nor for a neutralized governor. See Refresh in
-- GovernorPanel.lua.
function SentientSystems_IsAssignable(governor, definition)
	return not SentientSystems_IsCannotAssign(definition) and governor:GetNeutralizedTurns() == 0
end

-- Returns the game's reasons a governor can't be assigned to a city, as text,
-- or nil when they can. The chooser checks the cities of city-states and the
-- capitals of other players this way, and shows the reasons with the city
-- turned off. See RefreshBottomPanel in GovernorAssignmentChooser.lua.
local function GetBlockedReasons(governors, definition, city)
	local allowed, results = governors:CanAssignGovernor(definition.Hash, city, true)

	if allowed then
		return nil
	end

	return SentientSystems_GetFailureReasons(results, PlayerOperationResults.FAILURE_REASONS)
end

-- Returns the places a governor can go, in the chooser's order, each a table
-- of the city and the reasons it is turned off, or nil. These are each of the
-- player's cities but the one the governor is in, then for an Ambassador the
-- cities of the city-states the player has met, then for a governor that can
-- govern abroad the capitals of the players they have met. See
-- RefreshBottomPanel in GovernorAssignmentChooser.lua, and AddCityInstance.
function SentientSystems_GetAssignTargets(player, governors, governor, definition)
	local current = governor:GetAssignedCity()
	local targets = {}

	local function Add(city, reasons)
		if current == nil or current:GetOwner() ~= city:GetOwner() or current:GetID() ~= city:GetID() then
			targets[#targets + 1] = { city = city, reasons = reasons }
		end
	end

	for _, city in player:GetCities():Members() do
		Add(city)
	end

	if governor:IsGovernCityState() then
		for _, cityState in ipairs(PlayerManager.GetAliveMinors()) do
			local influence = cityState:GetInfluence()

			if influence ~= nil and influence:CanReceiveInfluence() and player:GetDiplomacy():HasMet(cityState:GetID()) then
				for _, city in cityState:GetCities():Members() do
					Add(city, GetBlockedReasons(governors, definition, city))
				end
			end
		end
	end

	if governor:CanAssignToMajorCiv() then
		for _, major in ipairs(PlayerManager.GetAliveMajors()) do
			local capital = player:GetDiplomacy():HasMet(major:GetID()) and major:GetCities():GetCapitalCity()

			if capital then
				Add(capital, GetBlockedReasons(governors, definition, capital))
			end
		end
	end

	return targets
end
