-- The pantheon and religion actions. SentientSystemsCore_Actions.lua loads
-- this file. The calls are in docs/findings/actions/religion.md.

SentientSystems_Include("SentientSystemsCore_Religion")

-- Returns why the player can't found a pantheon now, or nil. The launch bar
-- opens the pantheon chooser only for a player with no pantheon who can create
-- one. See LaunchBar.lua.
local function GetPantheonFailure(religion)
	local pantheon = religion:GetPantheon()

	if pantheon >= 0 then
		return "You have a pantheon already, " .. GameInfo.Beliefs[pantheon].BeliefType .. "."
	end

	if not religion:CanCreatePantheon() then
		return "You can't found a pantheon yet. The choices list a pantheon once you can."
	end

	return nil
end

-- Returns the row of the belief by its type, or nil and the reason. choice
-- names the choice that lists the beliefs to pick from.
local function FindBeliefRow(typeName, choice)
	local row = type(typeName) == "string" and GameInfo.Beliefs[typeName] or nil

	if row == nil then
		return nil, tostring(typeName) .. " isn't a belief. Use a type from the " .. choice .. " choice."
	end

	return row, nil
end

-- Returns why the belief can't be the player's pantheon, or nil. See
-- CanSelectBelief in PantheonChooser.lua.
local function GetPantheonBeliefFailure(row)
	if row.BeliefClassType ~= "BELIEF_CLASS_PANTHEON" then
		return row.BeliefType .. " isn't a pantheon belief. Use a type from the pantheon choice."
	end

	if SentientSystems_IsBeliefTaken(Game.GetReligion(), row.Index) then
		return "Another player has " .. row.BeliefType .. " already. Use a type from the pantheon choice."
	end

	return nil
end

-- Sends the request the pantheon chooser sends. See ConfirmPantheon in
-- PantheonChooser.lua.
local function RequestPantheon(playerID, row)
	local parameters = {
		[PlayerOperations.PARAM_BELIEF_TYPE] = row.Hash,
		[PlayerOperations.PARAM_INSERT_MODE] = PlayerOperations.VALUE_EXCLUSIVE,
	}

	UI.RequestPlayerOperation(playerID, PlayerOperations.FOUND_PANTHEON, parameters)
end

local function FoundPantheon(playerID, typeName)
	local failure = GetPantheonFailure(SentientSystems_GetPlayer(playerID):GetReligion())

	if failure ~= nil then
		return failure
	end

	local row

	row, failure = FindBeliefRow(typeName, "pantheon")

	if failure ~= nil then
		return failure
	end

	failure = GetPantheonBeliefFailure(row)

	if failure ~= nil then
		return failure
	end

	RequestPantheon(playerID, row)

	return nil
end

-- Founds the player's pantheon with the belief and returns the result as JSON.
-- The belief is a type from the pantheon choice, such as
-- BELIEF_RELIGIOUS_SETTLEMENTS.
function SentientSystems_FoundPantheon(playerID, belief)
	return SentientSystems_RunAction("FoundPantheon", FoundPantheon, playerID, belief)
end
