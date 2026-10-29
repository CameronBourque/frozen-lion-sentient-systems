-- The World Congress choice: what the player decides in a session of the World Congress, and looks
-- at when one has ended, as the congress screen shows it. SentientSystemsCore_Choices.lua loads this
-- file. Example: SentientSystems_GetWorldCongressChoices(player) returns a table that encodes as
-- '{"favor":196,"proposals":[{"description":"...","name":"Aid Request","sender":11,"target":11,
-- "type":"WC_EMERGENCY_REQUEST_AID"}],"resolutions":[],"session":"special",
-- "voteCosts":[0,4,12,24,40,60,84,112,144,180]}', on one line. The checks follow PopulateResolutions,
-- PopulateProposals, PopulateReview, PopulateActiveEffects, and PopulateEmergencyProposals in
-- WorldCongressPopup.lua. Checked in a running game for a Special Session only.

-- Returns a player's name as the game shows it: the leader's name once the player has met them, and
-- the unmet player text before. See GetVisiblePlayerNameAndIcons in PlayerSupport.lua, lines 39 to 90.
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

-- Returns the proposals of a call such as GetProposals, each with its category's cost, sorted by
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

-- Returns the target of a resolution that passed, as the review shows it: a player's name for a player
-- target, and the game's text for anything else.
local function GetChosenTarget(data, localPlayerID)
	if data.TargetType == "PlayerType" then
		local playerID = tonumber(data.ChosenThing)

		return playerID ~= -1 and GetPlayerName(playerID, localPlayerID) or ""
	end

	return Locale.Lookup(data.ChosenThing)
end

-- Returns the resolutions in effect or just decided, from a call that returns the chosen outcome of
-- each, each with name, elected, the label of the outcome, A or B, text, the outcome, and target. Adds
-- turnsLeft when given, and, from the review's player selections, votes, the votes for A and B, and
-- voters, each with player, name, option, A or B, target, what they chose it for, and votes.
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

-- Returns the resolutions to vote on in a regular session, each with type, such as
-- RESOLUTION_LUXURY_POLICY, name, options, with A and B, the text of each outcome, targetType, the
-- kind of target, such as ResourceType or PlayerType, targets, each with index, the number the vote
-- sends, name, and player, the player's ID, for a player target, and favored and disfavored, the
-- player IDs the game says favor or oppose it. See PopulateResolutions, lines 569 to 686.
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

-- Returns the proposals on the floor to vote for or against, each with type, such as
-- WC_EMERGENCY_BACKSTAB, name, description, sender, the proposing player's ID, and target, the
-- target player's ID. See PopulateProposalStack, lines 1227 to 1325.
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

-- Returns the proposals the player could call a Special Session for, each with type, name,
-- description, target, cost, in Favor, and disabled, true for one the game won't take. See
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

-- Returns the World Congress choice: favor, the player's Diplomatic Favor, and, in a session, session,
-- regular for one with resolutions, and special for one without, voteCosts, the Favor for 1, 2, and so
-- on up to the most votes, in total, resolutions, and proposals. Out of a session, it has available,
-- the proposals the player could call a Special Session for, left out with none, and, while the
-- look-at-results blocker is up, session, review, results, the last session's resolutions, each with
-- name, elected, text, target, votes, and voters, and effects, the resolutions in effect, with turnsLeft.
-- Returns nil with nothing to show. The congress screen opens only from its notification, so the
-- session and the results read only while their blocker is up. See SetStage in
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
