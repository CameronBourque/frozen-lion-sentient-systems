-- The World Congress choice: what the player decides in a session of the World
-- Congress, and looks at when one has ended, as the congress screen shows it.
-- SentientSystemsCore_Choices.lua loads this file. The shape is in
-- bridge/src/choices/world-congress.ts. The checks follow PopulateResolutions,
-- PopulateProposals, PopulateReview, PopulateActiveEffects, and
-- PopulateEmergencyProposals in WorldCongressPopup.lua. Checked in a running
-- game for a Special Session only.

-- Returns a player's name as the game shows it: the leader's name once the
-- player has met them, and the unmet player text before. See
-- GetVisiblePlayerNameAndIcons in PlayerSupport.lua, lines 39 to 90.
local function GetPlayerName(playerID, localPlayerID)
	if playerID ~= localPlayerID and not Players[localPlayerID]:GetDiplomacy():HasMet(playerID) then
		return Locale.Lookup("LOC_DIPLOPANEL_UNMET_PLAYER")
	end

	return Locale.Lookup(PlayerConfigurations[playerID]:GetPlayerName())
end

-- Returns a list as a sorted list of its numbers.
local function Numbers(list)
	local numbers = {}

	for _, value in pairs(list or {}) do
		numbers[#numbers + 1] = tonumber(value)
	end

	table.sort(numbers)

	return numbers
end

-- Returns the proposals of a call such as GetProposals, each with its
-- category's cost, sorted by type so the order doesn't depend on the game's
-- hashes.
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

-- Returns the target of a resolution that passed, as the review shows it: a
-- player's name for a player target, and the game's text for anything else.
local function GetChosenTarget(data, localPlayerID)
	if data.TargetType == "PlayerType" then
		local playerID = tonumber(data.ChosenThing)

		return playerID ~= -1 and GetPlayerName(playerID, localPlayerID) or ""
	end

	return Locale.Lookup(data.ChosenThing)
end

-- Returns the resolutions in effect or just decided, from a call that returns
-- the chosen outcome of each. Adds turnsLeft when given, and the votes and
-- voters from the review's player selections.
local function GetOutcomes(data, localPlayerID, turnsLeft)
	local outcomes = {}

	for _, resolution in pairs(data) do
		if type(resolution) == "table" then
			local outcome = {
				name = Locale.Lookup(GameInfo.Resolutions[resolution.Type].Name),
				elected = resolution.ChosenLabel,
				text = Locale.Lookup(resolution.ChosenOption),
				target = GetChosenTarget(resolution, localPlayerID),
				turnsLeft = turnsLeft,
			}

			if resolution.PlayerSelections ~= nil then
				outcome.votes = { A = 0, B = 0 }
				outcome.voters = {}

				for _, selection in pairs(resolution.PlayerSelections) do
					local side = selection.OptionChosen == 1 and "A" or "B"
					local playerID = tonumber(selection.PlayerID)
					local chosen = { TargetType = resolution.TargetType, ChosenThing = selection.ResolutionTarget }

					outcome.votes[side] = outcome.votes[side] + selection.Votes
					outcome.voters[#outcome.voters + 1] = {
						player = playerID,
						name = GetPlayerName(playerID, localPlayerID),
						option = side,
						target = GetChosenTarget(chosen, localPlayerID),
						votes = selection.Votes,
					}
				end

				table.sort(outcome.voters, function(a, b)
					return a.player < b.player
				end)
			end

			outcomes[#outcomes + 1] = outcome
		end
	end

	table.sort(outcomes, function(a, b)
		return a.name < b.name
	end)

	return outcomes
end

-- Returns the resolutions to vote on in a regular session. See
-- PopulateResolutions, lines 569 to 686.
local function GetResolutions(data, localPlayerID)
	local resolutions = {}

	for i, resolution in pairs(data) do
		if type(i) == "number" then
			local row = GameInfo.Resolutions[resolution.Type]
			local targets = {}

			for index, target in ipairs(resolution.PossibleTargets) do
				if resolution.TargetType == "PlayerType" then
					local playerID = tonumber(target)

					targets[index] = { index = index, player = playerID, name = GetPlayerName(playerID, localPlayerID) }
				else
					targets[index] = { index = index, name = Locale.Lookup(target) }
				end
			end

			resolutions[#resolutions + 1] = {
				type = row.ResolutionType,
				name = Locale.Lookup(row.Name),
				options = { A = Locale.Lookup(row.Effect1Description), B = Locale.Lookup(row.Effect2Description) },
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
-- PopulateProposalStack, lines 1227 to 1325.
local function GetProposals(data)
	local proposals = {}

	for _, entry in ipairs(GetProposalEntries(data.Proposals)) do
		local proposal = entry.proposal

		proposals[#proposals + 1] = {
			type = proposal.TypeName,
			name = proposal.Name,
			description = proposal.Description,
			sender = proposal.Sender,
			target = proposal.Target,
		}
	end

	return proposals
end

-- Returns the proposals the player could call a Special Session for. See
-- PopulateEmergencyProposals, lines 1763 to 1786.
local function GetAvailable(data)
	local available = {}

	for _, entry in ipairs(GetProposalEntries(data.Proposals)) do
		local proposal = entry.proposal

		available[#available + 1] = {
			type = proposal.TypeName,
			name = proposal.Name,
			description = proposal.Description,
			target = proposal.Target,
			cost = entry.cost,
			disabled = proposal.Disabled == true,
		}
	end

	return available
end

-- Returns the World Congress choice. Returns nil with nothing to show. The
-- congress screen opens only from its notification, so the session and the
-- results read only while their blocker is up. See SetStage in
-- WorldCongressPopup.lua, lines 164 to 246.
function SentientSystems_GetWorldCongressChoices(player)
	local playerID = player:GetID()
	local congress = Game.GetWorldCongress()
	local choice = {}

	if congress:IsInSession() then
		if not SentientSystems_HasBlocker(playerID, "ENDTURN_BLOCKING_WORLD_CONGRESS_SESSION") then
			return nil
		end

		local costs = congress:GetVotesandFavorCost(playerID)
		local voteCosts = {}

		for votes = 1, costs.MaxVotes do
			voteCosts[votes] = costs[votes - 1]
		end

		choice.resolutions = GetResolutions(congress:GetResolutions(playerID), playerID)
		choice.proposals = GetProposals(congress:GetProposals(playerID))
		choice.session = #choice.resolutions > 0 and "regular" or "special"
		choice.voteCosts = voteCosts
	else
		local available = GetAvailable(congress:GetEmergencies(playerID))

		choice.available = #available > 0 and available or nil

		if SentientSystems_HasBlocker(playerID, "ENDTURN_BLOCKING_WORLD_CONGRESS_LOOK") then
			local turnsLeft = congress:GetMeetingStatus().TurnsLeft + 1

			choice.session = "review"
			choice.results = GetOutcomes(congress:GetReview(playerID).Resolutions, playerID)
			choice.effects = GetOutcomes(congress:GetResolutions(playerID), playerID, turnsLeft)
		elseif choice.available == nil then
			return nil
		end
	end

	choice.favor = player:GetFavor()

	return choice
end
