-- The congress screen's rules that the World Congress choice and the congress
-- actions share: the session's resolutions, proposals, and vote costs, and the
-- proposals the player could make. Follows WorldCongressPopup.lua.

include("SentientSystemsCore_Common")

-- A resolution's two options, each with the letter the choice names it by,
-- the number the screen sends, and the column of its effect's text. See
-- OnVoteResolution in WorldCongressPopup.lua.
SENTIENTSYSTEMS_RESOLUTION_OPTIONS = {
	{ key = "A", number = 1, column = "Effect1Description" },
	{ key = "B", number = 2, column = "Effect2Description" },
}

-- Returns the resolution option with the letter or the screen's number, or
-- nil. The choice reads a vote by its number, and the action by its letter.
function SentientSystems_FindResolutionOption(keyOrNumber)
	for _, option in ipairs(SENTIENTSYSTEMS_RESOLUTION_OPTIONS) do
		if option.key == keyOrNumber or option.number == keyOrNumber then
			return option
		end
	end

	return nil
end

-- Returns a player's name as the game shows it: the leader's name once the
-- player has met them, and the unmet player text before. See
-- GetVisiblePlayerNameAndIcons in PlayerSupport.lua.
function SentientSystems_GetCongressPlayerName(playerID, localPlayerID)
	if playerID ~= localPlayerID and not Players[localPlayerID]:GetDiplomacy():HasMet(playerID) then
		return Locale.Lookup("LOC_DIPLOPANEL_UNMET_PLAYER")
	end

	return Locale.Lookup(PlayerConfigurations[playerID]:GetPlayerName())
end

local function Numbers(list)
	local numbers = {}

	for _, value in pairs(list or {}) do
		numbers[#numbers + 1] = tonumber(value)
	end

	table.sort(numbers)

	return numbers
end

-- Returns the proposals of a call, each with its category's cost, sorted by
-- type so the order doesn't depend on the game's hashes.
local function GetProposalEntries(categories)
	local entries = {}

	for _, category in pairs(categories or {}) do
		for _, proposal in ipairs(category.ProposalsOfType) do
			entries[#entries + 1] = { proposal = proposal, cost = category.FavorCost }
		end
	end

	table.sort(entries, function(a, b)
		return a.proposal.TypeName < b.proposal.TypeName
	end)

	return entries
end

-- Returns the resolutions to vote on in a regular session. See
-- PopulateResolutions.
local function GetResolutions(data, localPlayerID)
	local resolutions = {}

	for i, resolution in pairs(data) do
		if type(i) == "number" then
			local row = GameInfo.Resolutions[resolution.Type]
			local targets = {}

			for index, target in ipairs(resolution.PossibleTargets) do
				if resolution.TargetType == "PlayerType" then
					local playerID = tonumber(target)

					targets[index] = { index = index, player = playerID, name = SentientSystems_GetCongressPlayerName(playerID, localPlayerID) }
				else
					targets[index] = { index = index, name = Locale.Lookup(target) }
				end
			end

			local options = {}

			for _, option in ipairs(SENTIENTSYSTEMS_RESOLUTION_OPTIONS) do
				options[option.key] = SentientSystems_LookupText(row[option.column])
			end

			resolutions[#resolutions + 1] = {
				type = row.ResolutionType,
				name = Locale.Lookup(row.Name),
				options = options,
				targetType = resolution.TargetType,
				targets = targets,
				favored = Numbers(resolution.FavoredPlayerIDs),
				disfavored = Numbers(resolution.DisfavoredPlayerIDs),
			}
		end
	end

	table.sort(resolutions, function(a, b)
		return a.type < b.type
	end)

	return resolutions
end

-- Returns the proposals on the floor to vote for or against. See
-- PopulateProposalStack.
local function GetFloorProposals(data)
	local proposals = {}

	for _, entry in ipairs(GetProposalEntries(data.Proposals)) do
		local proposal = entry.proposal

		proposals[#proposals + 1] = {
			type = proposal.TypeName,
			name = proposal.Name,
			description = SentientSystems_CleanText(proposal.Description),
			sender = proposal.Sender,
			target = proposal.Target,
		}
	end

	return proposals
end

-- Returns the session the player votes in: its resolutions, its proposals,
-- and the Favor each number of votes costs, by the number. Returns nil out of
-- session, or while its blocker is down: the screen opens only from the
-- blocker's notification. See SetStage in WorldCongressPopup.lua.
function SentientSystems_GetCongressSession(player)
	local playerID = player:GetID()
	local congress = Game.GetWorldCongress()

	if not congress:IsInSession() or not SentientSystems_HasBlocker(playerID, "ENDTURN_BLOCKING_WORLD_CONGRESS_SESSION") then
		return nil
	end

	local costs = congress:GetVotesandFavorCost(playerID)
	local voteCosts = {}

	for votes = 1, costs.MaxVotes do
		voteCosts[votes] = costs[votes - 1]
	end

	return {
		resolutions = GetResolutions(congress:GetResolutions(playerID), playerID),
		proposals = GetFloorProposals(congress:GetProposals(playerID)),
		voteCosts = voteCosts,
	}
end

-- Returns the proposals the player could call a Special Session for, out of
-- session. See PopulateEmergencyProposals.
function SentientSystems_GetCongressAvailable(player)
	local available = {}

	for _, entry in ipairs(GetProposalEntries(Game.GetWorldCongress():GetEmergencies(player:GetID()).Proposals)) do
		local proposal = entry.proposal

		available[#available + 1] = {
			type = proposal.TypeName,
			name = proposal.Name,
			description = SentientSystems_CleanText(proposal.Description),
			target = proposal.Target,
			cost = entry.cost,
			disabled = proposal.Disabled == true,
		}
	end

	return available
end
