-- Techs and civics. A player's techs has current, the tech in research, and options, the techs the
-- player knows, each with type, cost, turns, progress, boost, with percent, trigger, and triggered,
-- unlocks, description, a text key, recommended, locked, which CanResearch refuses, and for the tech
-- tree, era, which is ERA_ANCIENT when missing, researched, hidden, which IsTechRevealed refuses, and
-- prerequisites, by type. techs.turnsLeft is what GetTurnsLeft returns. A player's civics has the
-- same, with civic types. The player's science and its tooltip are here, and its culture is in
-- FakeGame.lua. Governments and policies are in FakeGame/Governments.lua, which is registered after
-- this file.

return function(env, world, ctx)
	local AddRow, indexes, hashes = ctx.AddRow, ctx.indexes, ctx.hashes

	env.GameInfo.Technologies = ctx.TypedRows({}, "TechnologyType")
	env.GameInfo.Civics = ctx.TypedRows({}, "CivicType")
	env.GameInfo.Boosts = ctx.TypedRows({}, "TechnologyType")

	-- Each tech and civic gets a row, a hash, and a boost row when it has a boost. The game's
	-- GetUnlockablesForTech and GetUnlockablesForCivic return what one unlocks as { type, name, key }
	-- rows.
	local unlocksByType = {}

	for _, data in pairs(world.players or {}) do
		for _, kind in ipairs({ { data.techs, "Technologies", "TechnologyType" }, { data.civics, "Civics", "CivicType" } }) do
			for _, option in ipairs((kind[1] or {}).options or {}) do
				AddRow(kind[2], kind[3], option.type)

				local row = env.GameInfo[kind[2]][indexes[option.type]]

				row.Hash = ctx.NextHash(4000000, option.type)
				row.Description = option.description
				row.EraType = option.era or "ERA_ANCIENT"
				unlocksByType[option.type] = option.unlocks

				if option.boost ~= nil then
					local boosts = env.GameInfo.Boosts

					boosts[#boosts + (boosts[0] and 1 or 0)] = { [kind[3]] = option.type, Boost = option.boost.percent, TriggerDescription = option.boost.trigger }
				end
			end
		end
	end

	-- Returns the unlock rows of a tech or civic type.
	local function UnlockRows(typeName)
		local rows = {}

		for i, unlock in ipairs(unlocksByType[typeName] or {}) do
			rows[i] = { unlock, unlock, unlock }
		end

		return rows
	end

	env.GetFilteredUnlockableItems = function()
		return {}
	end
	env.GetUnlockablesForTech = UnlockRows
	env.GetUnlockablesForCivic = UnlockRows

	-- Returns the nodes of a tree from player 0's techs or civics, in order, with their type in
	-- nameField, Name for a tech and CivicName for a civic, and their prerequisites in field.
	local function TreeNodes(key, nameField, field)
		local nodes = {}
		local options = (((world.players or {})[0] or {})[key] or {}).options or {}

		for i, option in ipairs(options) do
			nodes[i] = { [nameField] = option.type, [field] = option.prerequisites or {} }
		end

		return nodes
	end

	env.UITree = {
		GetAvailableTechs = function()
			return TreeNodes("techs", "Name", "PrereqTechTypes")
		end,
		GetAvailableCivics = function()
			return TreeNodes("civics", "CivicName", "PrereqCivicTypes")
		end,
	}

	ctx.OnPlayer(function(player, data)
		local techData, civicData = data.techs or {}, data.civics or {}

		-- Each tech and civic option by its GameInfo index.
		local techsByIndex, civicsByIndex = {}, {}

		for _, tech in ipairs(techData.options or {}) do
			techsByIndex[indexes[tech.type]] = tech
		end

		for _, civic in ipairs(civicData.options or {}) do
			civicsByIndex[indexes[civic.type]] = civic
		end

		player.GetTechs = function()
			return {
				GetScienceYield = function()
					return data.science or 0
				end,
				GetScienceYieldToolTip = function()
					return (data.tooltips or {}).science or ""
				end,
				GetResearchingTech = function()
					return techData.current and indexes[techData.current] or -1
				end,
				CanResearch = function(_, index)
					return techsByIndex[index] ~= nil and not techsByIndex[index].locked
				end,
				GetResearchCost = function(_, index)
					return techsByIndex[index].cost
				end,
				GetResearchProgress = function(_, index)
					return techsByIndex[index].progress or 0
				end,
				GetTurnsToResearch = function(_, index)
					return techsByIndex[index].turns
				end,
				HasBoostBeenTriggered = function(_, index)
					return techsByIndex[index].boost.triggered == true
				end,
				HasTech = function(_, index)
					return techsByIndex[index] ~= nil and techsByIndex[index].researched == true
				end,
				IsTechRevealed = function(_, index)
					return techsByIndex[index] ~= nil and techsByIndex[index].hidden ~= true
				end,
				GetTurnsLeft = function()
					return techData.turnsLeft or -1
				end,
			}
		end

		local GetCulture = player.GetCulture

		function player.GetCulture()
			local culture = GetCulture()

			culture.GetProgressingCivic = function()
				return civicData.current and indexes[civicData.current] or -1
			end

			culture.CanProgress = function(_, index)
				return civicsByIndex[index] ~= nil and not civicsByIndex[index].locked
			end

			culture.GetCultureCost = function(_, index)
				return civicsByIndex[index].cost
			end

			culture.GetCulturalProgress = function(_, index)
				return civicsByIndex[index].progress or 0
			end

			culture.GetTurnsToProgressCivic = function(_, index)
				return civicsByIndex[index].turns
			end

			culture.HasCivic = function(_, index)
				return civicsByIndex[index] ~= nil and civicsByIndex[index].researched == true
			end

			culture.IsCivicRevealed = function(_, index)
				return civicsByIndex[index] ~= nil and civicsByIndex[index].hidden ~= true
			end

			culture.GetTurnsLeft = function()
				return civicData.turnsLeft or -1
			end

			culture.HasBoostBeenTriggered = function(_, index)
				return civicsByIndex[index].boost.triggered == true
			end

			return culture
		end

		player.GetGrandStrategicAI = function()
			-- Returns the recommended options, each with its hash in field.
			local function Recommendations(options, field)
				local recommendations = {}

				for _, option in ipairs(options or {}) do
					if option.recommended then
						recommendations[#recommendations + 1] = { [field] = hashes[option.type] }
					end
				end

				return recommendations
			end

			return {
				GetTechRecommendations = function()
					return Recommendations(techData.options, "TechHash")
				end,
				GetCivicsRecommendations = function()
					return Recommendations(civicData.options, "CivicHash")
				end,
			}
		end
	end)
end
