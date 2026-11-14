-- The deal, session, and war actions of the diplomacy screens.
-- SentientSystemsCore_Actions.lua loads this file. The calls are in
-- docs/findings/actions/diplomacy.md and ai-sessions.md.

SentientSystems_Include("SentientSystemsCore_StateProposals")
SentientSystems_Include("SentientSystemsCore_StateSessions")

-- Accepts the deal as the screen's Accept button does, from the copy the screen
-- makes when the deal arrives. See OnProposeOrAcceptDeal in
-- DiplomacyDealView.lua.
local function AcceptDeal(playerID, otherPlayerID, deal)
	deal:Validate()

	if not deal:IsValid() then
		return "The deal from player " .. otherPlayerID .. " is no longer valid. Reject it."
	end

	DealManager.CopyIncomingToOutgoingWorkingDeal(playerID, otherPlayerID)
	DealManager.SendWorkingDeal(DealProposalAction.ACCEPTED, playerID, otherPlayerID)

	return nil
end

-- Answers the deal the other player has put to the player, then closes the
-- session, as the leader screen does when the player leaves it. A refusal is
-- the response that the deal screen's Refuse button adds. See OnRefuseDeal in
-- DiplomacyDealView.lua, and ExitConversationMode in DiplomacyActionView.lua.
local function RespondToDeal(playerID, otherPlayerID, accept)
	SentientSystems_GetPlayer(playerID)
	SentientSystems_GetPlayer(otherPlayerID)

	local deal, sessionID = SentientSystems_GetProposedDeal(playerID, otherPlayerID)

	if deal == nil then
		return "Player " .. otherPlayerID .. " has no deal waiting for you. The proposals section lists the deals put to you."
	end

	if accept then
		local failure = AcceptDeal(playerID, otherPlayerID, deal)

		if failure ~= nil then
			return failure
		end
	else
		DiplomacyManager.AddResponse(sessionID, playerID, "NEGATIVE")
	end

	DiplomacyManager.CloseSession(sessionID)

	return nil
end

-- Accepts or rejects the deal another player has put to the player, and
-- returns the result as JSON.
function SentientSystems_RespondToDeal(playerID, otherPlayerID, accept)
	return SentientSystems_RunAction("RespondToDeal", RespondToDeal, playerID, otherPlayerID, accept)
end

-- The response that the leader screen adds for each option. The goodbye closes
-- the session, and any other key is its own response. See
-- OnSelectConversationDiplomacyStatement in DiplomacyActionView.lua.
local RESPONSES = {
	CHOICE_POSITIVE = "POSITIVE",
	CHOICE_NEGATIVE = "NEGATIVE",
	CHOICE_IGNORE = "RESPONSE_IGNORE",
	CHOICE_STOP_ASKING = "REJECTED_PERMANENT",
}

local function FindSessionOption(options, key)
	for _, option in ipairs(options) do
		if option.key == key then
			return option
		end
	end

	return nil
end

local function GetOptionKeys(options)
	local keys = {}

	for i, option in ipairs(options) do
		keys[i] = option.key
	end

	return table.concat(keys, ", ")
end

-- Returns why the player can't answer the session with the option, or nil.
-- The checks are those of the sessions section, so they match what the agent
-- read.
local function GetSessionFailure(playerID, otherPlayerID, entry, option)
	local who = "Player " .. otherPlayerID

	if entry == nil and SentientSystems_GetProposedDeal(playerID, otherPlayerID) ~= nil then
		return who .. "'s session holds a deal. Answer it with the deal response."
	end

	if entry == nil then
		return who .. " has no leader screen open with you. The sessions section lists them."
	end

	if entry.queued then
		return who .. "'s session waits behind another one. Answer that one first."
	end

	if entry.unknown then
		return option ~= SENTIENTSYSTEMS_GOODBYE and "The core mod didn't see what " .. who:lower() .. " said, so only " .. SENTIENTSYSTEMS_GOODBYE .. " can answer it." or nil
	end

	local found = FindSessionOption(entry.options, option)

	if found == nil then
		return who .. "'s session doesn't offer " .. tostring(option) .. ". It offers " .. GetOptionKeys(entry.options) .. "."
	end

	if found.disabled ~= nil then
		return tostring(option) .. " is disabled: " .. found.disabled
	end

	return nil
end

-- Answers the leader screen the other player has open with the player, as a
-- click on the option does. A response can lead to another statement in the
-- same session, which the sessions section then lists.
local function RespondToSession(playerID, otherPlayerID, option)
	local player = SentientSystems_GetPlayer(playerID)

	SentientSystems_GetPlayer(otherPlayerID)

	local entry, sessionID = SentientSystems_GetSessionEntry(player, otherPlayerID)
	local failure = GetSessionFailure(playerID, otherPlayerID, entry, option)

	if failure ~= nil then
		return failure
	end

	if option == SENTIENTSYSTEMS_GOODBYE then
		DiplomacyManager.CloseSession(sessionID)
	else
		DiplomacyManager.AddResponse(sessionID, playerID, RESPONSES[option] or option)
	end

	return nil
end

-- Answers the other player's leader screen with an option key from the
-- sessions section, and returns the result as JSON.
function SentientSystems_RespondToSession(playerID, otherPlayerID, option)
	return SentientSystems_RunAction("RespondToSession", RespondToSession, playerID, otherPlayerID, option)
end

-- Returns whether the player is a city-state, which the war popup and the
-- city-state screen tell apart from a major civ by its level.
local function IsCityState(playerID)
	local level = PlayerConfigurations[playerID]:GetCivilizationLevelTypeID()

	return level ~= CivilizationLevelTypes.CIVILIZATION_LEVEL_FULL_CIV
end

-- Returns the game's reasons that the leader screen's check gives for the
-- action, or the fallback when the check fails with none, or nil. See
-- DiplomacySupport_RemoveInvalidSelections in DiplomacyStatementSupport.lua.
local function GetActionFailure(diplomacy, actionType, otherPlayerID, fallback)
	local valid, results = diplomacy:IsDiplomaticActionValid(actionType, otherPlayerID, true)

	if valid then
		return nil
	end

	return SentientSystems_GetFailureReasons(results, "FailureReasons", " ") or fallback
end

-- Returns why the player can't open a diplomacy session with the other player
-- now, or nil. A new session waits behind an open one, and closing it there
-- cancels it. A city-state's operation opens no session.
local function GetOpenSessionFailure(playerID, otherPlayerID)
	if IsCityState(otherPlayerID) then
		return nil
	end

	for otherID = 0, 63 do
		local sessionID = DiplomacyManager.FindOpenSessionID(playerID, otherID)

		if otherID ~= playerID and sessionID ~= nil and sessionID ~= -1 then
			return "A diplomacy session with player " .. otherID .. " is open. Answer it first."
		end
	end

	return nil
end

-- Returns why the player can't declare a surprise war on the other player, or
-- nil. The game's check gives no reason for a player already at war.
local function GetWarFailure(diplomacy, otherPlayerID)
	if not diplomacy:HasMet(otherPlayerID) then
		return "You haven't met player " .. otherPlayerID .. "."
	end

	if diplomacy:IsAtWarWith(otherPlayerID) then
		return "You are already at war with player " .. otherPlayerID .. "."
	end

	local fallback = "The game doesn't allow a war with player " .. otherPlayerID .. " now."

	return GetActionFailure(diplomacy, "DIPLOACTION_DECLARE_SURPRISE_WAR", otherPlayerID, fallback)
end

-- Returns the parameters of a war or peace operation with a city-state.
local function GetPlayerPairParams(playerID, otherPlayerID)
	local P = PlayerOperations

	return { [P.PARAM_PLAYER_ONE] = playerID, [P.PARAM_PLAYER_TWO] = otherPlayerID }
end

-- Declares a surprise war as the war popup does: a diplomacy session for a
-- major civ, and a player operation for a city-state. See DeclareWar in
-- DeclareWarPopup.lua. The war takes effect when the request is sent, so the
-- session closes at once, as the leader screen does when the player leaves it.
local function DeclareWar(playerID, otherPlayerID)
	local player = SentientSystems_GetPlayer(playerID)

	SentientSystems_GetPlayer(otherPlayerID)

	local failure = GetWarFailure(player:GetDiplomacy(), otherPlayerID) or GetOpenSessionFailure(playerID, otherPlayerID)

	if failure ~= nil then
		return failure
	end

	if IsCityState(otherPlayerID) then
		UI.RequestPlayerOperation(playerID, PlayerOperations.DIPLOMACY_DECLARE_WAR, GetPlayerPairParams(playerID, otherPlayerID))
	else
		DiplomacyManager.RequestSession(playerID, otherPlayerID, "DECLARE_SURPRISE_WAR")
		DiplomacyManager.CloseSession(DiplomacyManager.FindOpenSessionID(playerID, otherPlayerID))
	end

	return nil
end

-- Declares a surprise war on the other player, and returns the result as JSON.
function SentientSystems_DeclareWar(playerID, otherPlayerID)
	return SentientSystems_RunAction("DeclareWar", DeclareWar, playerID, otherPlayerID)
end

-- Returns why the player can't propose peace to the other player, or nil. The
-- city-state screen checks CanMakePeaceWith, and gives no reason from the game.
local function GetPeaceFailure(diplomacy, otherPlayerID)
	if not diplomacy:HasMet(otherPlayerID) then
		return "You haven't met player " .. otherPlayerID .. "."
	end

	if not diplomacy:IsAtWarWith(otherPlayerID) then
		return "You aren't at war with player " .. otherPlayerID .. "."
	end

	local fallback = "The game doesn't allow peace with player " .. otherPlayerID .. " now."

	if not IsCityState(otherPlayerID) then
		return GetActionFailure(diplomacy, "DIPLOACTION_MAKE_PEACE", otherPlayerID, fallback)
	end

	if not diplomacy:CanMakePeaceWith(otherPlayerID) then
		return fallback .. " A city-state makes peace only some turns after the war began, and not while you are at war with its suzerain."
	end

	return nil
end

-- Sets the outgoing deal to peace alone, as the leader screen's Make Peace
-- does. Validating the deal adds peace on the other side, and any city that
-- the peace returns. See OnSelectInitialDiplomacyStatement in
-- DiplomacyActionView.lua.
local function SetPeaceDeal(playerID, otherPlayerID)
	DealManager.ClearWorkingDeal(DealDirection.OUTGOING, playerID, otherPlayerID)

	local deal = DealManager.GetWorkingDeal(DealDirection.OUTGOING, playerID, otherPlayerID)
	local item = deal:AddItemOfType(DealItemTypes.AGREEMENTS, playerID)

	item:SetSubType(DealAgreementTypes.MAKE_PEACE)
	item:SetLocked(true)
	deal:Validate()
end

-- Proposes peace as the leader screen does for a major civ, with the deal and
-- the deal screen's Propose, and as the city-state screen does for a
-- city-state. An AI answers after the call, so the result says only that the
-- proposal went out. See ProposeWorkingDeal in DiplomacyDealView.lua and
-- OnChangeWarPeaceStatus in CityStates.lua.
local function ProposePeace(playerID, otherPlayerID)
	local player = SentientSystems_GetPlayer(playerID)

	SentientSystems_GetPlayer(otherPlayerID)

	local failure = GetPeaceFailure(player:GetDiplomacy(), otherPlayerID) or GetOpenSessionFailure(playerID, otherPlayerID)

	if failure ~= nil then
		return failure
	end

	if IsCityState(otherPlayerID) then
		UI.RequestPlayerOperation(playerID, PlayerOperations.DIPLOMACY_MAKE_PEACE, GetPlayerPairParams(playerID, otherPlayerID))

		return nil
	end

	SetPeaceDeal(playerID, otherPlayerID)
	DiplomacyManager.RequestSession(playerID, otherPlayerID, "MAKE_DEAL")
	DealManager.SendWorkingDeal(DealProposalAction.PROPOSED, playerID, otherPlayerID)
	DiplomacyManager.CloseSession(DiplomacyManager.FindOpenSessionID(playerID, otherPlayerID))

	return nil
end

-- Proposes peace to the other player, and returns the result as JSON.
function SentientSystems_ProposePeace(playerID, otherPlayerID)
	return SentientSystems_RunAction("ProposePeace", ProposePeace, playerID, otherPlayerID)
end

local function GetPeaceResult(playerID, otherPlayerID)
	if SentientSystems_GetPlayer(playerID):GetDiplomacy():IsAtWarWith(otherPlayerID) then
		return "Player " .. otherPlayerID .. " hasn't accepted peace. You are still at war."
	end

	return nil
end

-- Returns whether the war with the other player has ended, as an action
-- result in JSON. The bridge reads it after a proposal of peace.
function SentientSystems_GetPeaceResult(playerID, otherPlayerID)
	return SentientSystems_RunAction("GetPeaceResult", GetPeaceResult, playerID, otherPlayerID)
end
