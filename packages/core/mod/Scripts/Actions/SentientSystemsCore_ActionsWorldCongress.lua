-- The World Congress actions on the congress screen: the votes of a session.
-- SentientSystemsCore_Actions.lua loads this file. The calls are in
-- docs/findings/actions/world-congress.md.

SentientSystems_Include("SentientSystemsCore_WorldCongress")

local function NameProposal(type, target)
	return tostring(type) .. " with target " .. tostring(target)
end

-- Returns the resolution with the type, or nil.
local function FindResolution(session, type)
	for _, resolution in ipairs(session.resolutions) do
		if resolution.type == type then
			return resolution
		end
	end

	return nil
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

local function IsWholeNumber(value, most)
	return type(value) == "number" and value >= 1 and value <= most and value % 1 == 0
end

-- Returns why a number of votes can't be cast, or nil. The screen stops at the
-- most votes its costs list, so this does too. See OnVoteResolution.
local function GetCountFailure(session, vote, name)
	local most = #session.voteCosts

	if not IsWholeNumber(vote.votes, most) then
		return "Cast 1 to " .. most .. " votes on " .. name .. ", not " .. tostring(vote.votes) .. "."
	end

	return nil
end

-- Returns why a vote on a resolution can't be cast, or nil. The screen needs
-- one option and one of the option's targets. See PopulateChoicePulldown.
local function GetResolutionVoteFailure(session, resolution, vote)
	local name = resolution.type

	if type(vote.option) ~= "string" or SentientSystems_FindResolutionOption(vote.option) == nil then
		return "Choose option A or B for " .. name .. ", not " .. tostring(vote.option) .. "."
	end

	if not IsWholeNumber(vote.target, #resolution.targets) then
		return "Choose a target from 1 to " .. #resolution.targets .. " for " .. name .. ", not " .. tostring(vote.target) .. ". Use the index of one of its targets."
	end

	return GetCountFailure(session, vote, name)
end

-- Returns why a vote on a proposal can't be cast, or nil. See OnVoteProposal.
local function GetProposalVoteFailure(session, vote)
	local name = NameProposal(vote.type, vote.target)

	if FindProposal(session, vote) == nil then
		return name .. " isn't a resolution or a proposal on the floor. Use one of " .. ListProposals(session) .. "."
	end

	local failure = GetCountFailure(session, vote, name)

	return failure and failure .. " Leave a proposal out to abstain."
end

-- Returns why a vote can't be cast, or nil. A vote whose type is a
-- resolution's is a resolution vote, and any other is a proposal vote.
local function GetVoteFailure(session, vote, seen)
	if type(vote) ~= "table" then
		return "Each vote is a table with a type, a target, and votes."
	end

	local resolution = FindResolution(session, vote.type)
	local key = resolution and resolution.type or NameProposal(vote.type, vote.target)

	if seen[key] then
		return "You voted on " .. key .. " twice. Give each one vote."
	end

	seen[key] = true

	if resolution ~= nil then
		return GetResolutionVoteFailure(session, resolution, vote)
	end

	return GetProposalVoteFailure(session, vote)
end

-- Returns why the votes can't be cast, or nil: a vote that fails, a
-- resolution with no vote, which the screen won't accept, or a total cost
-- above the player's Favor. Each item's votes cost what the session lists for
-- that many. See CanMoveToNextPhase and UpdateWorkingFavor.
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

	for _, resolution in ipairs(session.resolutions) do
		if not seen[resolution.type] then
			return "Vote on every resolution. " .. resolution.type .. " has no vote."
		end
	end

	if cost > favor then
		return "These votes cost " .. cost .. " Favor, and you have " .. favor .. "."
	end

	return nil
end

-- Sends one vote on a resolution, with its option and the target's place in
-- the game's list, which counts from 0. See OnAccept.
local function RequestResolutionVote(playerID, vote)
	local P = PlayerOperations

	UI.RequestPlayerOperation(playerID, P.WORLD_CONGRESS_RESOLUTION_VOTE, {
		[P.PARAM_RESOLUTION_TYPE] = GameInfo.Resolutions[vote.type].Hash,
		[P.PARAM_WORLD_CONGRESS_VOTES] = vote.votes,
		[P.PARAM_RESOLUTION_OPTION] = SentientSystems_FindResolutionOption(vote.option).number,
		[P.PARAM_RESOLUTION_SELECTION] = vote.target - 1,
	})
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

	-- The screen sends the resolution votes first, then the proposal votes.
	for _, vote in ipairs(votes) do
		if FindResolution(session, vote.type) ~= nil then
			RequestResolutionVote(playerID, vote)
		end
	end

	for _, vote in ipairs(votes) do
		if FindResolution(session, vote.type) == nil then
			RequestProposalVote(playerID, FindProposal(session, vote), vote)
		end
	end

	-- The screen submits after its votes, with any proposal left out as an
	-- abstention.
	UI.RequestPlayerOperation(playerID, PlayerOperations.WORLD_CONGRESS_SUBMIT_TURN, {})

	return nil
end

-- Casts the player's votes in a World Congress session and submits them, and
-- returns the result as JSON. Each vote names a resolution of the
-- worldCongress choice by its type, with an option, A or B, a target's index,
-- and its votes, or a proposal by its type and target, with its votes, and
-- against to oppose it.
function SentientSystems_VoteInCongress(playerID, votes)
	return SentientSystems_RunAction("VoteInCongress", VoteInCongress, playerID, votes)
end
