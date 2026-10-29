-- The World Congress. world.congress is the World Congress, with inSession, turnsLeft, maxVotes,
-- costs, the game's cost table from 0, resolutions, each with type, targetType, targets, the game's
-- possible targets, favored, and disfavored, proposals, each with the game's TypeName, Name,
-- Description, Sender, and Target, available, the same with Disabled and cost, effects, each with
-- type, targetType, and the game's ChosenLabel, ChosenOption, and ChosenThing, and review, the same
-- with PlayerSelections, each with OptionChosen and Votes. world.congressInSession puts the World
-- Congress in session.

return function(env, world, ctx)
	local indexes = ctx.indexes

	env.GameInfo.Resolutions = {}
	env.EndTurnBlockingTypes.ENDTURN_BLOCKING_WORLD_CONGRESS_LOOK = 1215684003
	env.EndTurnBlockingTypes.ENDTURN_BLOCKING_WORLD_CONGRESS_SESSION = 1215684004

	-- Each resolution in the World Congress gets a row, with the text keys the screen reads.
	local congress = world.congress or {}

	for _, list in ipairs({ congress.resolutions or {}, congress.effects or {}, congress.review or {} }) do
		for _, resolution in ipairs(list) do
			ctx.AddRow("Resolutions", "ResolutionType", resolution.type)

			local row = env.GameInfo.Resolutions[indexes[resolution.type]]

			row.Name = "LOC_" .. resolution.type .. "_NAME"
			row.Effect1Description = "LOC_" .. resolution.type .. "_A"
			row.Effect2Description = "LOC_" .. resolution.type .. "_B"
		end
	end

	-- The World Congress, from world.congress. The calls that take a player's ID give the voting
	-- entries in a session, as the game does, and the chosen outcomes out of one.
	env.Game.GetWorldCongress = function()
		-- Returns proposals as the game groups them, each in a category with its cost.
		local function Categories(list)
			local categories = {}

			for i, proposal in ipairs(list or {}) do
				categories[i] = { FavorCost = proposal.cost, ProposalsOfType = { proposal } }
			end

			return { Proposals = categories }
		end

		-- Returns outcomes with the game's index for each resolution type.
		local function Outcomes(list)
			local outcomes = {}

			for i, outcome in ipairs(list or {}) do
				outcomes[i] = {}

				for key, value in pairs(outcome) do
					outcomes[i][key] = value
				end

				outcomes[i].Type = indexes[outcome.type]
			end

			return outcomes
		end

		return {
			IsInSession = function()
				return world.congressInSession == true or congress.inSession == true
			end,
			GetMeetingStatus = function()
				return { TurnsLeft = congress.turnsLeft or 0 }
			end,
			GetVotesandFavorCost = function()
				local costs = { MaxVotes = congress.maxVotes }

				for votes, cost in pairs(congress.costs or {}) do
					costs[votes] = cost
				end

				return costs
			end,
			GetResolutions = function()
				if not congress.inSession then
					return Outcomes(congress.effects)
				end

				local resolutions = { Stage = 1 }

				for i, resolution in ipairs(congress.resolutions or {}) do
					resolutions[i] = {
						Type = indexes[resolution.type],
						TargetType = resolution.targetType,
						PossibleTargets = resolution.targets,
						FavoredPlayerIDs = resolution.favored or {},
						DisfavoredPlayerIDs = resolution.disfavored or {},
					}
				end

				return resolutions
			end,
			GetProposals = function()
				return Categories(congress.proposals)
			end,
			GetEmergencies = function()
				return Categories(congress.available)
			end,
			GetReview = function()
				return { Resolutions = Outcomes(congress.review), Discussions = {} }
			end,
		}
	end
end
