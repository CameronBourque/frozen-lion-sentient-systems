-- The governor choice: appointments, promotions, and assignments, as the
-- Governors panel and its choosers offer them. Needs Rise and Fall.
-- Follows GovernorPanel.lua. Shape: bridge/src/choices/governors.ts.

SentientSystems_Include("SentientSystemsCore_Governors")

-- Returns the governors the player can appoint. A Secret Society the player has
-- discovered is there too, without the loyalty and turns that its card doesn't
-- show. Returns nil without a title to spend, as the panel turns every Appoint
-- button off then. See Refresh in GovernorPanel.lua, AddGovernorCandidate, and
-- AddSecretGovernorCandidate.
local function GetAppointments(governors)
	if not governors:CanAppoint() then
		return nil
	end

	local list = {}

	for definition in GameInfo.Governors() do
		local hash = definition.Hash

		if not governors:HasGovernor(hash) and governors:CanEverAppointGovernor(hash) then
			local secret = SentientSystems_IsCannotAssign(definition)

			list[#list + 1] = {
				type = definition.GovernorType,
				name = Locale.Lookup(definition.Name),
				title = Locale.Lookup(definition.Title),
				description = SentientSystems_LookupText(definition.Description),
				secret = secret and true or nil,
				loyalty = not secret and definition.IdentityPressure or nil,
				turnsToEstablish = not secret and governors:GetTurnsToEstablish(hash) or nil,
			}
		end
	end

	return #list > 0 and list or nil
end

-- Returns the promotions a governor can earn now, in the game's order. See
-- CreatePromotionTree in GovernorDetailsPanel.lua, and
-- CreateSecretPromotionTree.
local function GetPromotions(governors, governor, definition)
	local promotions = {}

	for set in GameInfo.GovernorPromotionSets() do
		if set.GovernorType == definition.GovernorType then
			local promotion = GameInfo.GovernorPromotions[set.GovernorPromotion]

			if not governor:HasPromotion(promotion.Hash) and governors:CanEarnPromotion(definition.Hash, promotion.Hash) then
				local name, description, hidden = SentientSystems_GetPromotionTexts(promotion, governor)

				promotions[#promotions + 1] = { type = promotion.GovernorPromotionType, name = name, description = description, hidden = hidden }
			end
		end
	end

	return promotions
end

local function GetTarget(city, reasons)
	return { owner = city:GetOwner(), id = city:GetID(), name = Locale.Lookup(city:GetName()), blocked = reasons }
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

	local reasons = {}

	for i, reason in ipairs(results and results[PlayerOperationResults.FAILURE_REASONS] or {}) do
		reasons[i] = SentientSystems_LookupText(reason)
	end

	return reasons
end

-- Returns the places a governor can go, in the chooser's order: each of the
-- player's cities but the one they are in, then for an Ambassador the cities of
-- the city-states the player has met, then for a governor that can govern
-- abroad the capitals of the players they have met. See RefreshBottomPanel in
-- GovernorAssignmentChooser.lua, and AddCityInstance.
local function GetAssignments(player, governors, governor, definition)
	local current = governor:GetAssignedCity()
	local targets = {}

	local function Add(city, reasons)
		if current == nil or current:GetOwner() ~= city:GetOwner() or current:GetID() ~= city:GetID() then
			targets[#targets + 1] = GetTarget(city, reasons)
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

-- Returns the governor choice, each key left out with nothing to offer. A
-- neutralized governor can't be assigned, as the panel turns its Assign button
-- off. Returns nil without Rise and Fall, with nothing to do, and while
-- Gathering Storm's World Congress is in session, which turns every button off.
-- See Refresh in GovernorPanel.lua, and IsReadOnly.
function SentientSystems_GetGovernorChoices(player)
	if player.GetGovernors == nil or (SentientSystems_HasExpansion2() and Game.GetWorldCongress():IsInSession()) then
		return nil
	end

	local governors = player:GetGovernors()
	local _, list = governors:GetGovernorList()
	local promote, assign = {}, {}

	for _, governor in ipairs(list or {}) do
		local definition = GameInfo.Governors[governor:GetType()]

		if governors:CanPromoteGovernor(definition.Hash) then
			local promotions = GetPromotions(governors, governor, definition)

			if #promotions > 0 then
				promote[#promote + 1] = { governor = definition.GovernorType, promotions = promotions }
			end
		end

		if not SentientSystems_IsCannotAssign(definition) and governor:GetNeutralizedTurns() == 0 then
			assign[#assign + 1] = { governor = definition.GovernorType, cities = GetAssignments(player, governors, governor, definition) }
		end
	end

	local choice = {
		appoint = GetAppointments(governors),
		promote = #promote > 0 and promote or nil,
		assign = #assign > 0 and assign or nil,
	}

	if choice.appoint == nil and choice.promote == nil and choice.assign == nil then
		return nil
	end

	return choice
end
