-- The deal and war actions of the diplomacy screens.
-- SentientSystemsCore_Actions.lua loads this file. The calls are in
-- docs/findings/actions/diplomacy.md.

SentientSystems_Include("SentientSystemsCore_StateProposals")

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

-- Returns why the player can't declare a surprise war on the other player, or
-- nil. The game's check gives no reason for a player already at war. See
-- DiplomacySupport_RemoveInvalidSelections in DiplomacyStatementSupport.lua.
local function GetWarFailure(diplomacy, otherPlayerID)
	if not diplomacy:HasMet(otherPlayerID) then
		return "You haven't met player " .. otherPlayerID .. "."
	end

	if diplomacy:IsAtWarWith(otherPlayerID) then
		return "You are already at war with player " .. otherPlayerID .. "."
	end

	local valid, results = diplomacy:IsDiplomaticActionValid("DIPLOACTION_DECLARE_SURPRISE_WAR", otherPlayerID, true)

	if valid then
		return nil
	end

	local reasons = {}

	for i, reason in ipairs(results and results.FailureReasons or {}) do
		reasons[i] = Locale.Lookup(reason)
	end

	if #reasons == 0 then
		return "The game doesn't allow a war with player " .. otherPlayerID .. " now."
	end

	return table.concat(reasons, " ")
end

-- Returns why the player can't open a diplomacy session now, or nil. A new
-- session waits behind an open one, and closing it there cancels it.
local function GetOpenSessionFailure(playerID)
	for otherID = 0, 63 do
		local sessionID = DiplomacyManager.FindOpenSessionID(playerID, otherID)

		if otherID ~= playerID and sessionID ~= nil and sessionID ~= -1 then
			return "A diplomacy session with player " .. otherID .. " is open. Answer it first."
		end
	end

	return nil
end

-- Declares a surprise war as the war popup does: a diplomacy session for a
-- major civ, and a player operation for a city-state. See DeclareWar in
-- DeclareWarPopup.lua. The war takes effect when the request is sent, so the
-- session closes at once, as the leader screen does when the player leaves it.
local function DeclareWar(playerID, otherPlayerID)
	local player = SentientSystems_GetPlayer(playerID)

	SentientSystems_GetPlayer(otherPlayerID)

	local failure = GetWarFailure(player:GetDiplomacy(), otherPlayerID) or GetOpenSessionFailure(playerID)

	if failure ~= nil then
		return failure
	end

	local level = PlayerConfigurations[otherPlayerID]:GetCivilizationLevelTypeID()

	if level == CivilizationLevelTypes.CIVILIZATION_LEVEL_FULL_CIV then
		DiplomacyManager.RequestSession(playerID, otherPlayerID, "DECLARE_SURPRISE_WAR")
		DiplomacyManager.CloseSession(DiplomacyManager.FindOpenSessionID(playerID, otherPlayerID))
	else
		local P = PlayerOperations

		UI.RequestPlayerOperation(playerID, P.DIPLOMACY_DECLARE_WAR, { [P.PARAM_PLAYER_ONE] = playerID, [P.PARAM_PLAYER_TWO] = otherPlayerID })
	end

	return nil
end

-- Declares a surprise war on the other player, and returns the result as JSON.
function SentientSystems_DeclareWar(playerID, otherPlayerID)
	return SentientSystems_RunAction("DeclareWar", DeclareWar, playerID, otherPlayerID)
end
