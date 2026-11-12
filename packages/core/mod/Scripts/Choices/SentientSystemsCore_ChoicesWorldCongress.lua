-- The World Congress choice, as the congress screen shows it. Follows
-- the Populate* functions in WorldCongressPopup.lua.
-- Shape: bridge/src/choices/world-congress.ts.

SentientSystems_Include("SentientSystemsCore_WorldCongress")

-- Returns the target of a resolution that passed, as the review shows it: a
-- player's name for a player target, and the game's text for anything else.
local function GetChosenTarget(data, localPlayerID)
	if data.TargetType == "PlayerType" then
		local playerID = tonumber(data.ChosenThing)

		return playerID ~= -1 and SentientSystems_GetCongressPlayerName(playerID, localPlayerID) or ""
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
				text = SentientSystems_LookupText(resolution.ChosenOption),
				target = GetChosenTarget(resolution, localPlayerID),
				turnsLeft = turnsLeft,
			}

			if resolution.PlayerSelections ~= nil then
				outcome.votes = {}

				for _, option in ipairs(SENTIENTSYSTEMS_RESOLUTION_OPTIONS) do
					outcome.votes[option.key] = 0
				end

				outcome.voters = {}

				for _, selection in pairs(resolution.PlayerSelections) do
					local side = SentientSystems_FindResolutionOption(selection.OptionChosen).key
					local playerID = tonumber(selection.PlayerID)
					local chosen = { TargetType = resolution.TargetType, ChosenThing = selection.ResolutionTarget }

					outcome.votes[side] = outcome.votes[side] + selection.Votes
					outcome.voters[#outcome.voters + 1] = {
						player = playerID,
						name = SentientSystems_GetCongressPlayerName(playerID, localPlayerID),
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

-- Returns the World Congress choice. Returns nil with nothing to show. The
-- congress screen opens only from its notification, so the session and the
-- results read only while their blocker is up. See SetStage in
-- WorldCongressPopup.lua.
function SentientSystems_GetWorldCongressChoices(player)
	local playerID = player:GetID()
	local congress = Game.GetWorldCongress()
	local choice = {}

	if congress:IsInSession() then
		local session = SentientSystems_GetCongressSession(player)

		if session == nil then
			return nil
		end

		choice.resolutions = session.resolutions
		choice.proposals = session.proposals
		choice.session = #session.resolutions > 0 and "regular" or "special"
		choice.voteCosts = session.voteCosts
	else
		local available = SentientSystems_GetCongressAvailable(player)

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
