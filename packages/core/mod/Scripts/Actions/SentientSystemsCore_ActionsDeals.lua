-- The deal actions on the deal screen. SentientSystemsCore_Actions.lua loads
-- this file. The calls are in docs/findings/actions/diplomacy.md.

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
