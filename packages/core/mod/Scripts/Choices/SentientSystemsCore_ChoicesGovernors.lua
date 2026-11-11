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

		if SentientSystems_IsAppointable(governors, definition) then
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
local function GetEarnablePromotions(governors, governor, definition)
	local promotions = {}

	for _, promotion in ipairs(SentientSystems_GetPromotionRows(definition)) do
		if SentientSystems_IsPromotionEarnable(governors, governor, definition, promotion) then
			local name, description, hidden = SentientSystems_GetPromotionTexts(promotion, governor)

			promotions[#promotions + 1] = { type = promotion.GovernorPromotionType, name = name, description = description, hidden = hidden }
		end
	end

	return promotions
end

-- Returns the places a governor can go, in the chooser's order, each with the
-- reasons it is turned off. See SentientSystems_GetAssignTargets.
local function GetAssignments(player, governors, governor, definition)
	local cities = {}

	for i, target in ipairs(SentientSystems_GetAssignTargets(player, governors, governor, definition)) do
		local city = target.city

		cities[i] = { owner = city:GetOwner(), id = city:GetID(), name = Locale.Lookup(city:GetName()), blocked = target.reasons }
	end

	return cities
end

-- Returns the governor choice, each key left out with nothing to offer. A
-- neutralized governor can't be assigned, as the panel turns its Assign button
-- off. Returns nil with nothing to do, and while the panel is closed. See
-- SentientSystems_GetGovernorsClosedReason.
function SentientSystems_GetGovernorChoices(player)
	if SentientSystems_GetGovernorsClosedReason(player) ~= nil then
		return nil
	end

	local governors = player:GetGovernors()
	local _, list = governors:GetGovernorList()
	local promote, assign = {}, {}

	for _, governor in ipairs(list or {}) do
		local definition = GameInfo.Governors[governor:GetType()]

		if governors:CanPromoteGovernor(definition.Hash) then
			local promotions = GetEarnablePromotions(governors, governor, definition)

			if #promotions > 0 then
				promote[#promote + 1] = { governor = definition.GovernorType, promotions = promotions }
			end
		end

		if SentientSystems_IsAssignable(governor, definition) then
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
