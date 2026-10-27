-- The governor choice: the governors the player can appoint, the promotions they can give their
-- governors, and the cities they can assign them to, as the Governors panel, its details panel, and
-- its assignment chooser offer them. Rise and Fall adds governors, so without it there is no choice.
-- SentientSystemsCore_Choices.lua loads this file. Example: SentientSystems_GetGovernorChoices(player)
-- returns a table that encodes as '{"appoint":[{"description":"Military focused, ...","loyalty":8,
-- "name":"Victor","title":"The Castellan","turnsToEstablish":3,"type":"GOVERNOR_THE_DEFENDER"}],
-- "assign":[{"cities":[{"id":65536,"name":"Rome","owner":0},...],"governor":"GOVERNOR_THE_MERCHANT"}],
-- "promote":[{"governor":"GOVERNOR_THE_MERCHANT","promotions":[{"description":"Double adjacency
-- bonuses ...","name":"Harbormaster","type":"GOVERNOR_PROMOTION_MERCHANT_HARBORMASTER"}]}]}', on one
-- line. The checks follow GovernorPanel.lua, GovernorDetailsPanel.lua, and
-- GovernorAssignmentChooser.lua.

-- Returns whether a governor can't be assigned to a city, which only a Secret Societies governor
-- can't. See IsCannotAssign in GovernorSupport.lua, lines 110 to 125.
local function IsCannotAssign(definition)
	if GameInfo.GovernorsCannotAssign ~= nil then
		for row in GameInfo.GovernorsCannotAssign() do
			if row.GovernorType == definition.GovernorType then
				return row.CannotAssign
			end
		end
	end

	return false
end

-- Returns the governors the player can appoint, each with type, name, title, description, loyalty,
-- the loyalty pressure on their card, and turnsToEstablish, the turns they take to settle in a
-- city. Returns nil without a title to spend, as the panel turns every Appoint button off then. See
-- Refresh in GovernorPanel.lua, lines 39 to 122, and AddGovernorCandidate, lines 198 to 242.
local function GetAppointments(governors)
	if not governors:CanAppoint() then
		return nil
	end

	local list = {}

	for definition in GameInfo.Governors() do
		local hash = definition.Hash

		if not governors:HasGovernor(hash) and governors:CanEverAppointGovernor(hash) and not IsCannotAssign(definition) then
			list[#list + 1] = {
				type = definition.GovernorType,
				name = Locale.Lookup(definition.Name),
				title = Locale.Lookup(definition.Title),
				description = Locale.Lookup(definition.Description),
				loyalty = definition.IdentityPressure,
				turnsToEstablish = governors:GetTurnsToEstablish(hash),
			}
		end
	end

	return #list > 0 and list or nil
end

-- Returns the promotions a governor can earn now, each with type, name, and description, in the order
-- of the governor's promotion tree. See CreatePromotionTree in GovernorDetailsPanel.lua, lines 150
-- to 230.
local function GetPromotions(governors, governor, definition)
	local promotions = {}

	for set in GameInfo.GovernorPromotionSets() do
		if set.GovernorType == definition.GovernorType then
			local promotion = GameInfo.GovernorPromotions[set.GovernorPromotion]

			if not governor:HasPromotion(promotion.Hash) and governors:CanEarnPromotion(definition.Hash, promotion.Hash) then
				promotions[#promotions + 1] = {
					type = promotion.GovernorPromotionType,
					name = Locale.Lookup(promotion.Name),
					description = Locale.Lookup(promotion.Description),
				}
			end
		end
	end

	return promotions
end

-- Returns the city as an assignment target: owner, id, and name, with blocked, the game's reasons,
-- when the city can't take the governor.
local function GetTarget(city, reasons)
	return { owner = city:GetOwner(), id = city:GetID(), name = Locale.Lookup(city:GetName()), blocked = reasons }
end

-- Returns the game's reasons a governor can't be assigned to a city, as text, or nil when they can.
-- The chooser checks the cities of city-states and the capitals of other players this way, and
-- shows the reasons with the city turned off. See RefreshBottomPanel in GovernorAssignmentChooser.lua,
-- lines 153 to 226.
local function GetBlockedReasons(governors, definition, city)
	local allowed, results = governors:CanAssignGovernor(definition.Hash, city, true)

	if allowed then
		return nil
	end

	local reasons = {}

	for i, reason in ipairs(results and results[PlayerOperationResults.FAILURE_REASONS] or {}) do
		reasons[i] = Locale.Lookup(reason)
	end

	return reasons
end

-- Returns the places a governor can go, in the chooser's order: each of the player's cities but the
-- one they are in, then for an Ambassador the cities of the city-states the player has met, then for
-- a governor that can govern abroad the capitals of the players they have met. See
-- RefreshBottomPanel in GovernorAssignmentChooser.lua, lines 153 to 226, and AddCityInstance, lines
-- 228 to 262.
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

-- Returns the governor choice: appoint, the governors to appoint, promote, each governor that can be
-- promoted, with governor, its type, and promotions, assign, each governor that can be assigned,
-- with governor and cities, each key left out with nothing to offer. A neutralized governor can't be
-- assigned, as the panel turns its Assign button off. Returns nil without Rise and Fall, with
-- nothing to do, and while Gathering Storm's World Congress is in session, which turns every button
-- off. See Refresh in GovernorPanel.lua, lines 39 to 122, and IsReadOnly, lines 722 to 726.
function SentientSystems_GetGovernorChoices(player)
	if player.GetGovernors == nil or (SentientSystems_HasExpansion2() and Game.GetWorldCongress():IsInSession()) then
		return nil
	end

	local governors = player:GetGovernors()
	local _, list = governors:GetGovernorList()
	local promote, assign = {}, {}

	for _, governor in ipairs(list or {}) do
		local definition = GameInfo.Governors[governor:GetType()]

		if not IsCannotAssign(definition) then
			if governors:CanPromoteGovernor(definition.Hash) then
				local promotions = GetPromotions(governors, governor, definition)

				if #promotions > 0 then
					promote[#promote + 1] = { governor = definition.GovernorType, promotions = promotions }
				end
			end

			if governor:GetNeutralizedTurns() == 0 then
				assign[#assign + 1] = { governor = definition.GovernorType, cities = GetAssignments(player, governors, governor, definition) }
			end
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
