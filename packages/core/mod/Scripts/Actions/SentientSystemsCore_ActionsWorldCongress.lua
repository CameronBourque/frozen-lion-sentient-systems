-- The World Congress actions on the congress screen: the votes of a session.
-- SentientSystemsCore_Actions.lua loads this file. The calls are in
-- docs/findings/actions/world-congress.md.

SentientSystems_Include("SentientSystemsCore_WorldCongress")

local function NameProposal(type, target)
	return tostring(type) .. " with target " .. tostring(target)
end

-- Returns the proposal on the floor with the type and target, or nil.
local function FindProposal(session, vote)
	for _, proposal in ipairs(session.proposals) do
		if proposal.type == vote.type and proposal.target == vote.target then
			return proposal
		end
	end

	return nil
end

-- Returns the proposals on the floor, as a reason lists them.
local function ListProposals(session)
	local names = {}

	for i, proposal in ipairs(session.proposals) do
		names[i] = NameProposal(proposal.type, proposal.target)
	end

	return #names > 0 and table.concat(names, ", ") or "none"
end

-- Returns why a vote can't be cast, or nil. The screen stops at the most votes
-- its costs list, so this does too. See OnVoteProposal.
local function GetVoteFailure(session, vote, seen)
	if type(vote) ~= "table" then
		return "Each vote is a table with a type, a target, and votes."
	end

	local name = NameProposal(vote.type, vote.target)

	if FindProposal(session, vote) == nil then
		return name .. " isn't a proposal on the floor. Use one of " .. ListProposals(session) .. "."
	end

	if seen[name] then
		return "You voted on " .. name .. " twice. Give each proposal one vote."
	end

	seen[name] = true

	local count = vote.votes
	local most = #session.voteCosts

	if type(count) ~= "number" or count < 1 or count > most or count % 1 ~= 0 then
		return "Cast 1 to " .. most .. " votes on " .. name .. ", not " .. tostring(count) .. ". Leave a proposal out to abstain."
	end

	return nil
end

-- Returns why the votes can't be cast, or nil: a vote that fails, or a total
-- cost above the player's Favor. Each proposal's votes cost what the session
-- lists for that many. See OnVoteProposal and UpdateCostLabels.
local function GetVotesFailure(session, votes, favor)
	if type(votes) ~= "table" then
		return "The votes are a list of tables, each with a type, a target, and votes."
	end

	local seen, cost = {}, 0

	for _, vote in ipairs(votes) do
		local failure = GetVoteFailure(session, vote, seen)

		if failure ~= nil then
			return failure
		end

		cost = cost + session.voteCosts[vote.votes]
	end

	if cost > favor then
		return "These votes cost " .. cost .. " Favor, and you have " .. favor .. "."
	end

	return nil
end

-- Sends one vote for or against a proposal, keyed by its sender and target,
-- as the screen does. See OnAccept.
local function RequestProposalVote(playerID, proposal, vote)
	local P = PlayerOperations
	local direction = vote.against and -1 or 1

	UI.RequestPlayerOperation(playerID, P.WORLD_CONGRESS_DISCUSSION_VOTE, {
		[P.PARAM_PLAYER_ONE] = proposal.sender,
		[P.PARAM_PLAYER_TWO] = proposal.target,
		[P.PARAM_WORLD_CONGRESS_VOTES] = vote.votes * direction,
	})
end

local function VoteInCongress(playerID, votes)
	local player = SentientSystems_GetPlayer(playerID)
	local session = SentientSystems_GetCongressSession(player)

	if session == nil then
		return "There is no World Congress session to vote in. The worldCongress choice lists one while its session is up."
	end

	local failure = GetVotesFailure(session, votes, player:GetFavor())

	if failure ~= nil then
		return failure
	end

	for _, vote in ipairs(votes) do
		RequestProposalVote(playerID, FindProposal(session, vote), vote)
	end

	-- The screen submits after its votes, with any left out as abstentions.
	UI.RequestPlayerOperation(playerID, PlayerOperations.WORLD_CONGRESS_SUBMIT_TURN, {})

	return nil
end

-- Casts the player's votes in a World Congress session and submits them, and
-- returns the result as JSON. Each vote names a proposal of the worldCongress
-- choice by its type and target, with its votes, and against to oppose it.
function SentientSystems_VoteInCongress(playerID, votes)
	return SentientSystems_RunAction("VoteInCongress", VoteInCongress, playerID, votes)
end
