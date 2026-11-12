-- The World Congress actions: a session's votes and a Special Session's
-- proposals. SentientSystemsCore_Actions.lua loads this file. The calls are
-- in docs/findings/actions/world-congress.md.

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

-- Returns the proposal in the list with the type and target, or nil.
local function FindProposal(proposals, type, target)
	for _, proposal in ipairs(proposals) do
		if proposal.type == type and proposal.target == target then
			return proposal
		end
	end

	return nil
end

-- Returns the proposals in the list, as a reason lists them.
local function ListProposals(proposals)
	local names = {}

	for i, proposal in ipairs(proposals) do
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

	if FindProposal(session.proposals, vote.type, vote.target) == nil then
		return name .. " isn't a resolution or a proposal on the floor. Use one of " .. ListProposals(session.proposals) .. "."
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
			RequestProposalVote(playerID, FindProposal(session.proposals, vote.type, vote.target), vote)
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

-- Returns why a proposal can't be made, or nil. The screen lets the player
-- tick only a proposal it lists and hasn't turned off. See OnToggleProposal.
local function GetProposalFailure(available, proposal, seen)
	if type(proposal) ~= "table" then
		return "Each proposal is a table with a type and a target."
	end

	local name = NameProposal(proposal.type, proposal.target)
	local entry = FindProposal(available, proposal.type, proposal.target)

	if entry == nil then
		return name .. " isn't a proposal you can make. Use one of " .. ListProposals(available) .. "."
	end

	if seen[name] then
		return "You proposed " .. name .. " twice. Propose each once."
	end

	seen[name] = true

	if entry.disabled then
		return "You can't propose " .. name .. " now. The worldCongress choice lists it as disabled."
	end

	return nil
end

-- Returns why the proposals can't be made, or nil: a proposal that fails, or
-- a total cost above the player's Favor, which the screen checks as the
-- player ticks each one. See OnToggleProposal.
local function GetProposalsFailure(available, proposals, favor)
	if type(proposals) ~= "table" then
		return "The proposals are a list of tables, each with a type and a target."
	end

	local seen, cost = {}, 0

	for _, proposal in ipairs(proposals) do
		local failure = GetProposalFailure(available, proposal, seen)

		if failure ~= nil then
			return failure
		end

		cost = cost + FindProposal(available, proposal.type, proposal.target).cost
	end

	if cost > favor then
		return "These proposals cost " .. cost .. " Favor, and you have " .. favor .. "."
	end

	return nil
end

local function ProposeInCongress(playerID, proposals)
	local player = SentientSystems_GetPlayer(playerID)

	if Game.GetWorldCongress():IsInSession() then
		return "The World Congress is in session. Make proposals once it ends."
	end

	local available = SentientSystems_GetCongressAvailable(player)
	local failure = GetProposalsFailure(available, proposals, player:GetFavor())

	if failure ~= nil then
		return failure
	end

	local P = PlayerOperations

	-- Each ticked proposal sends its target and type. See OnAccept.
	for _, proposal in ipairs(proposals) do
		UI.RequestPlayerOperation(playerID, P.WORLD_CONGRESS_DISCUSSION_SELECTION, {
			[P.PARAM_OTHER_PLAYER] = proposal.target,
			[P.PARAM_DISCUSSION_TYPE] = GameInfo.Discussions[proposal.type].Hash,
		})
	end

	-- Closing the screen out of session tells the game the player has looked,
	-- which clears its blocker. See ClosePopup.
	UI.RequestPlayerOperation(playerID, P.WORLD_CONGRESS_LOOKED_AT_AVAILABLE, {})

	return nil
end

-- Calls a Special Session for the proposals, each from the available ones of
-- the worldCongress choice by its type and target, and marks the congress as
-- looked at. An empty list only marks it. Returns the result as JSON.
function SentientSystems_ProposeInCongress(playerID, proposals)
	return SentientSystems_RunAction("ProposeInCongress", ProposeInCongress, playerID, proposals)
end
