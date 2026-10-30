-- The governors. A player's governors has points, spent, and appointed, each with type, city,
-- with owner and id, established, turnsOnSite, turnsToEstablish, neutralized, loyalty, and
-- promotions, each with type, has, canEarn, base, true for the base ability, level, column, and
-- requires, the types of the promotions it follows, hiddenWithoutPrereqs, true for one that the panel
-- hides until its governor holds them, and canPromote, cityStates, true for one that can
-- govern city-states, and abroad, true for one that can go to other players' capitals. Its candidates
-- lists the governors it can appoint, each with type, canEver, false for one it never can,
-- turnsToEstablish, loyalty, and promotions, as for an appointed governor. canAppoint is false without a title, and cannotAssignTo maps "owner:id" of a city
-- to the reasons a governor can't go there. world.cannotAssign lists the governors of Secret
-- Societies. Without governors the player has no GetGovernors, as without Rise and Fall. A city's
-- governor is { type, established } for a governor, false for none in a game with Rise and Fall, and
-- missing without it, where the city has no GetAssignedGovernor.

return function(env, world, ctx)
	local AddRow, indexes = ctx.AddRow, ctx.indexes

	env.GameInfo.Governors = ctx.TypedRows({}, "GovernorType")
	env.GameInfo.GovernorPromotions = ctx.TypedRows({}, "GovernorPromotionType")
	env.GameInfo.GovernorPromotionSets = ctx.Callable({})
	env.GameInfo.GovernorsCannotAssign = ctx.Callable({})
	env.GameInfo.GovernorPromotionPrereqs = ctx.Callable({})
	env.GameInfo.GovernorPromotionConditions = ctx.Callable({})

	-- Each appointed governor gets a row, with its name, title, and a made-up hash, and each of its
	-- promotions a row and a place in its set.
	for _, data in pairs(world.players or {}) do
		local governorData = data.governors or {}

		-- Rows for a governor's promotions, with their place in its tree and their prerequisites.
		local function AddPromotions(governor)
			for _, promotion in ipairs(governor.promotions or {}) do
				AddRow("GovernorPromotions", "GovernorPromotionType", promotion.type)

				local promotionRow = env.GameInfo.GovernorPromotions[indexes[promotion.type]]

				promotionRow.Name = "LOC_" .. promotion.type .. "_NAME"
				promotionRow.Description = "LOC_" .. promotion.type .. "_DESCRIPTION"
				promotionRow.Level = promotion.level or 0
				promotionRow.Column = promotion.column or 0
				promotionRow.BaseAbility = promotion.base == true

				if promotion.hiddenWithoutPrereqs then
					table.insert(env.GameInfo.GovernorPromotionConditions, { GovernorPromotionType = promotion.type, HiddenWithoutPrereqs = true })
				end
				promotionRow.Hash = 4000000 + promotionRow.Index
				table.insert(env.GameInfo.GovernorPromotionSets, { GovernorType = governor.type, GovernorPromotion = promotion.type })

				for _, required in ipairs(promotion.requires or {}) do
					table.insert(env.GameInfo.GovernorPromotionPrereqs, { GovernorPromotionType = promotion.type, PrereqGovernorPromotion = required })
				end
			end
		end

		for _, governor in ipairs(governorData.candidates or {}) do
			AddRow("Governors", "GovernorType", governor.type)

			local row = env.GameInfo.Governors[indexes[governor.type]]

			row.Name = "LOC_" .. governor.type .. "_NAME"
			row.Title = "LOC_" .. governor.type .. "_TITLE"
			row.Description = "LOC_" .. governor.type .. "_DESCRIPTION"
			row.IdentityPressure = governor.loyalty or 8
			row.Hash = 3000000 + row.Index
			AddPromotions(governor)
		end

		for _, governor in ipairs(governorData.appointed or {}) do
			AddRow("Governors", "GovernorType", governor.type)

			local row = env.GameInfo.Governors[indexes[governor.type]]

			row.Name = "LOC_" .. governor.type .. "_NAME"
			row.Title = "LOC_" .. governor.type .. "_TITLE"
			row.Description = "LOC_" .. governor.type .. "_DESCRIPTION"
			row.IdentityPressure = 8
			row.Hash = 3000000 + row.Index
			AddPromotions(governor)
		end
	end

	-- The Secret Societies governors that can't be assigned to a city.
	for _, governorType in ipairs(world.cannotAssign or {}) do
		table.insert(env.GameInfo.GovernorsCannotAssign, { GovernorType = governorType, CannotAssign = true })
	end

	-- A city's governor gets a row.
	for _, data in pairs(world.players or {}) do
		for _, city in ipairs(data.cities or {}) do
			if city.governor then
				AddRow("Governors", "GovernorType", city.governor.type)
			end
		end
	end

	ctx.OnCity(function(city, data)
		city.GetAssignedGovernor = data.governor ~= nil and function()
			return data.governor and {
				GetType = function()
					return indexes[data.governor.type]
				end,
				IsEstablished = function()
					return data.governor.established == true
				end,
			}
		end or nil
	end)

	ctx.OnPlayer(function(player, data)
		-- The player's governors, from data.governors.
		if data.governors ~= nil then
			local governorData = data.governors

			player.GetGovernors = function()
				local list = {}

				for i, governor in ipairs(governorData.appointed or {}) do
					local held = {}

					for _, promotion in ipairs(governor.promotions or {}) do
						if promotion.has then
							held[env.GameInfo.GovernorPromotions[promotion.type].Hash] = true
						end
					end

					list[i] = {
						GetType = function()
							return indexes[governor.type]
						end,
						GetAssignedCity = function()
							local city = governor.city

							return city and {
								GetOwner = function()
									return city.owner
								end,
								GetID = function()
									return city.id
								end,
							}
						end,
						IsEstablished = function()
							return governor.established == true
						end,
						GetTurnsOnSite = function()
							return governor.turnsOnSite or 0
						end,
						GetTurnsToEstablish = function()
							return governor.turnsToEstablish or 5
						end,
						GetNeutralizedTurns = function()
							return governor.neutralized or 0
						end,
						GetIdentityPressure = function()
							return governor.loyalty or 8
						end,
						HasPromotion = function(_, hash)
							return held[hash] == true
						end,
						IsGovernCityState = function()
							return governor.cityStates == true
						end,
						CanAssignToMajorCiv = function()
							return governor.abroad == true
						end,
					}
				end

				-- The candidates by hash, and the promotions each appointed governor can earn.
				local candidates, earnable, appointed = {}, {}, {}

				for _, candidate in ipairs(governorData.candidates or {}) do
					candidates[env.GameInfo.Governors[indexes[candidate.type]].Hash] = candidate
				end

				for _, governor in ipairs(governorData.appointed or {}) do
					appointed[env.GameInfo.Governors[indexes[governor.type]].Hash] = governor

					for _, promotion in ipairs(governor.promotions or {}) do
						earnable[env.GameInfo.GovernorPromotions[indexes[promotion.type]].Hash] = promotion.canEarn == true
					end
				end

				return {
					GetGovernorPoints = function()
						return governorData.points or 0
					end,
					GetGovernorPointsSpent = function()
						return governorData.spent or 0
					end,
					GetGovernorList = function()
						return #list > 0, list
					end,
					CanAppoint = function()
						return governorData.canAppoint ~= false
					end,
					HasGovernor = function(_, hash)
						return appointed[hash] ~= nil
					end,
					CanEverAppointGovernor = function(_, hash)
						return candidates[hash] ~= nil and candidates[hash].canEver ~= false
					end,
					GetTurnsToEstablish = function(_, hash)
						return candidates[hash] and candidates[hash].turnsToEstablish or 5
					end,
					CanPromoteGovernor = function(_, hash)
						return appointed[hash] ~= nil and appointed[hash].canPromote == true
					end,
					CanEarnPromotion = function(_, _, promotionHash)
						return earnable[promotionHash] == true
					end,
					-- Whether a city can take a governor, from governorData.cannotAssignTo, with the game's
					-- failure reasons.
					CanAssignGovernor = function(_, _, city)
						local reasons = (governorData.cannotAssignTo or {})[city:GetOwner() .. ":" .. city:GetID()]

						if reasons == nil then
							return true, {}
						end

						return false, { [env.PlayerOperationResults.FAILURE_REASONS] = reasons }
					end,
				}
			end
		end
	end)
end
