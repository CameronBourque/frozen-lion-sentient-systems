-- The actions on the Governors panel: appoint, promote, and assign. Needs Rise
-- and Fall. SentientSystemsCore_Actions.lua loads this file. The calls are in
-- docs/findings/actions/governors.md.

SentientSystems_Include("SentientSystemsCore_Governors")

-- Returns the player's governors and the row of the governor by its type, or
-- nil and the reason.
local function FindGovernor(playerID, typeName)
	local player = SentientSystems_GetPlayer(playerID)
	local failure = SentientSystems_GetGovernorsClosedReason(player)

	if failure ~= nil then
		return nil, nil, failure
	end

	local definition = type(typeName) == "string" and GameInfo.Governors[typeName] or nil

	if definition == nil then
		return nil, nil, tostring(typeName) .. " isn't a governor. Use a type from the governors choice."
	end

	return player:GetGovernors(), definition, nil
end

-- Returns the player's appointed governor of the row, or nil and the reason.
local function FindAppointed(governors, definition)
	local _, list = governors:GetGovernorList()

	for _, governor in ipairs(list or {}) do
		if governor:GetType() == definition.Index then
			return governor, nil
		end
	end

	return nil, "You haven't appointed " .. definition.GovernorType .. ". Appoint them first."
end

-- Returns why the player can't appoint the governor, or nil. See Refresh in
-- GovernorPanel.lua.
local function GetAppointFailure(governors, definition)
	local typeName = definition.GovernorType

	if governors:HasGovernor(definition.Hash) then
		return "You have appointed " .. typeName .. " already."
	end

	if not SentientSystems_IsAppointable(governors, definition) then
		return "You can't appoint " .. typeName .. ". Use a type from the governors choice."
	end

	if not governors:CanAppoint() then
		return "You have no governor title to spend. The governors choice lists appointments once you do."
	end

	return nil
end

local function AppointGovernor(playerID, typeName)
	local governors, definition, failure = FindGovernor(playerID, typeName)

	failure = failure or GetAppointFailure(governors, definition)

	if failure ~= nil then
		return failure
	end

	UI.RequestPlayerOperation(playerID, PlayerOperations.APPOINT_GOVERNOR, { [PlayerOperations.PARAM_GOVERNOR_TYPE] = definition.Index })

	return nil
end

-- Returns the row of the governor's promotion by its type, or nil and the
-- reason.
local function FindPromotion(definition, typeName)
	for _, row in ipairs(SentientSystems_GetPromotionRows(definition)) do
		if row.GovernorPromotionType == typeName then
			return row, nil
		end
	end

	return nil, tostring(typeName) .. " isn't a promotion of " .. definition.GovernorType .. ". Use a type from the governors choice."
end

-- Returns why the governor can't earn the promotion now, or nil. See Refresh in
-- GovernorPanel.lua, and CreatePromotionTree in GovernorDetailsPanel.lua.
local function GetPromoteFailure(governors, governor, definition, promotion)
	if governor:HasPromotion(promotion.Hash) then
		return definition.GovernorType .. " has " .. promotion.GovernorPromotionType .. " already."
	end

	if not governors:CanPromoteGovernor(definition.Hash) then
		return "You have no governor title to spend on " .. definition.GovernorType .. ". The governors choice lists promotions once you do."
	end

	if not SentientSystems_IsPromotionEarnable(governors, governor, definition, promotion) then
		return definition.GovernorType .. " can't earn " .. promotion.GovernorPromotionType .. " yet. Use a type from the governors choice."
	end

	return nil
end

local function PromoteGovernor(playerID, typeName, promotionType)
	local governors, definition, failure = FindGovernor(playerID, typeName)
	local governor, promotion

	if failure == nil then
		governor, failure = FindAppointed(governors, definition)
	end

	if failure == nil then
		promotion, failure = FindPromotion(definition, promotionType)
	end

	failure = failure or GetPromoteFailure(governors, governor, definition, promotion)

	if failure ~= nil then
		return failure
	end

	local parameters = {
		[PlayerOperations.PARAM_GOVERNOR_TYPE] = definition.Index,
		[PlayerOperations.PARAM_GOVERNOR_PROMOTION_TYPE] = promotion.Index,
	}

	UI.RequestPlayerOperation(playerID, PlayerOperations.PROMOTE_GOVERNOR, parameters)

	return nil
end

-- Returns why the governor can't be assigned to any city, or nil. See Refresh
-- in GovernorPanel.lua.
local function GetAssignableFailure(governor, definition)
	if SentientSystems_IsCannotAssign(definition) then
		return definition.GovernorType .. " can't be assigned to a city."
	end

	if not SentientSystems_IsAssignable(governor, definition) then
		return definition.GovernorType .. " is neutralized for " .. governor:GetNeutralizedTurns() .. " more turns."
	end

	return nil
end

-- Returns the city the chooser offers the governor, by its owner and ID, or nil
-- and the reason. See RefreshBottomPanel in GovernorAssignmentChooser.lua.
local function FindTarget(player, governors, governor, definition, owner, cityID)
	local current = governor:GetAssignedCity()

	if current ~= nil and current:GetOwner() == owner and current:GetID() == cityID then
		return nil, definition.GovernorType .. " is in that city already."
	end

	for _, target in ipairs(SentientSystems_GetAssignTargets(player, governors, governor, definition)) do
		local city = target.city

		if city:GetOwner() == owner and city:GetID() == cityID then
			if target.reasons ~= nil then
				return nil, definition.GovernorType .. " can't go to " .. Locale.Lookup(city:GetName()) .. ". " .. table.concat(target.reasons, " ")
			end

			return city, nil
		end
	end

	return nil, "City " .. tostring(cityID) .. " of player " .. tostring(owner) .. " isn't a place " .. definition.GovernorType .. " can go. Use a city from the governors choice."
end

local function AssignGovernor(playerID, typeName, owner, cityID)
	local governors, definition, failure = FindGovernor(playerID, typeName)
	local governor

	if failure == nil then
		governor, failure = FindAppointed(governors, definition)
	end

	failure = failure or GetAssignableFailure(governor, definition)

	if failure == nil then
		_, failure = FindTarget(SentientSystems_GetPlayer(playerID), governors, governor, definition, owner, cityID)
	end

	if failure ~= nil then
		return failure
	end

	local parameters = {
		[PlayerOperations.PARAM_GOVERNOR_TYPE] = definition.Index,
		[PlayerOperations.PARAM_PLAYER_ONE] = owner,
		[PlayerOperations.PARAM_CITY_DEST] = cityID,
	}

	UI.RequestPlayerOperation(playerID, PlayerOperations.ASSIGN_GOVERNOR, parameters)

	return nil
end

-- Appoints the governor with a title and returns the result as JSON. The
-- governor is a type from the governors choice, such as GOVERNOR_THE_EDUCATOR.
function SentientSystems_AppointGovernor(playerID, governor)
	return SentientSystems_RunAction("AppointGovernor", AppointGovernor, playerID, governor)
end

-- Gives the appointed governor the promotion with a title and returns the
-- result as JSON. The promotion is a type from the governors choice.
function SentientSystems_PromoteGovernor(playerID, governor, promotion)
	return SentientSystems_RunAction("PromoteGovernor", PromoteGovernor, playerID, governor, promotion)
end

-- Sends the appointed governor to a city, by its owner and ID, and returns the
-- result as JSON. The city is one from the governors choice.
function SentientSystems_AssignGovernor(playerID, governor, owner, cityID)
	return SentientSystems_RunAction("AssignGovernor", AssignGovernor, playerID, governor, owner, cityID)
end
