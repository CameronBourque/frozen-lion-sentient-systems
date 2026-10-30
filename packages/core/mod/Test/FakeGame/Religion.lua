-- Religion. world.beliefs lists the ruleset's beliefs, each with type, class, BELIEF_CLASS_PANTHEON when
-- missing, description, and taken, true when a player's pantheon or religion holds it. A player's
-- pantheon is its belief type, and canCreatePantheon is true when it can found one. A player's
-- religion is the religion it founded, with type, name, beliefs, by type, and holyCity, a city ID,
-- beliefsEarned the beliefs it has earned, and prophet is true when it has a Great Prophet. A city's religions lists the religions
-- in it, each with type and followers, and majority is its majority religion's type.
-- world.pantheonFaith is the faith the next pantheon needs, 25 when missing. world.religions lists
-- more religions, each with type, pantheon, customName, and founded. A belief's tooMany is true
-- when a religion has too many of its class. The player's faith store is in FakeGame/Stores.lua.

return function(env, world, ctx)
	local AddRow, indexes = ctx.AddRow, ctx.indexes

	env.GameInfo.Beliefs = ctx.TypedRows({}, "BeliefType")
	env.GameInfo.Religions = ctx.TypedRows({}, "ReligionType")


	-- Each belief in world.beliefs gets a row.
	for _, belief in ipairs(world.beliefs or {}) do
		AddRow("Beliefs", "BeliefType", belief.type)

		local row = env.GameInfo.Beliefs[indexes[belief.type]]

		row.BeliefClassType = belief.class or "BELIEF_CLASS_PANTHEON"
		row.Description = belief.description
		row.taken = belief.taken
		row.tooMany = belief.tooMany
	end

	-- Each religion in world.religions gets a row.
	for _, religion in ipairs(world.religions or {}) do
		AddRow("Religions", "ReligionType", religion.type)

		local row = env.GameInfo.Religions[indexes[religion.type]]

		row.Pantheon = religion.pantheon == true
		row.RequiresCustomName = religion.customName == true
		row.founded = religion.founded
	end

	-- Each religion that a player founded or a city holds gets a row, with its name, and each of a
	-- founded religion's beliefs a belief row.
	for _, data in pairs(world.players or {}) do
		local religions = { data.religion }

		for _, city in ipairs(data.cities or {}) do
			for _, present in ipairs(city.religions or {}) do
				religions[#religions + 1] = present
			end
		end

		for _, religion in ipairs(religions) do
			AddRow("Religions", "ReligionType", religion.type)
			local row = env.GameInfo.Religions[indexes[religion.type]]

			row.Name = religion.name or row.Name or religion.type

			for _, belief in ipairs(religion.beliefs or {}) do
				AddRow("Beliefs", "BeliefType", belief)
			end
		end
	end

	ctx.OnCity(function(city, data)
		-- The religions in the city, from data.religions, each with type and followers, and the
		-- majority religion, from data.majority, by their GameInfo indexes.
		city.GetReligion = function()
			return {
				GetMajorityReligion = function()
					return data.majority and indexes[data.majority] or -1
				end,
				GetReligionsInCity = function()
					local present = {}

					for i, religion in ipairs(data.religions or {}) do
						present[i] = { Religion = indexes[religion.type] or -1, Followers = religion.followers }
					end

					return present
				end,
			}
		end
	end)

	ctx.OnPlayer(function(player, data, id)
		local GetReligion = player.GetReligion

		function player.GetReligion()
			local religion = GetReligion()

			-- The index of the player's pantheon belief, from data.pantheon, or -1 for none.
			function religion.GetPantheon()
				return data.pantheon and indexes[data.pantheon] or -1
			end

			function religion.CanCreatePantheon()
				return data.canCreatePantheon == true
			end

			-- The religion the player founded, from data.religion, with type and holyCity, a city ID.
			-- The beliefs earned come from data.beliefsEarned, the count of its beliefs when missing.
			local founded = data.religion or {}

			function religion.GetReligionTypeCreated()
				return founded.type and indexes[founded.type] or -1
			end

			function religion.GetHolyCityID()
				return { player = id, id = founded.holyCity }
			end

			function religion.GetNumBeliefsEarned()
				return data.beliefsEarned or #(founded.beliefs or {})
			end

			function religion.HasReligiousFoundingUnit()
				return data.prophet == true
			end

			return religion
		end
	end)

	-- Whether any player's pantheon or religion holds a belief, from each belief's taken.
	env.Game.GetReligion = function()
		local function IsTaken(_, index)
			return env.GameInfo.Beliefs[index].taken == true
		end

		return {
			IsInSomePantheon = IsTaken,
			IsInSomeReligion = IsTaken,
			IsTooManyForReligion = function(_, index)
				return env.GameInfo.Beliefs[index].tooMany == true
			end,
			HasBeenFounded = function(_, index)
				return env.GameInfo.Religions[index].founded == true
			end,
			GetMinimumFaithNextPantheon = function()
				return world.pantheonFaith or 25
			end,
			GetName = function(_, index)
				return env.GameInfo.Religions[index].Name
			end,
			-- Each founded religion, with its index, founder, and belief indexes.
			GetReligions = function()
				local religions = {}

				for playerID, data in pairs(world.players or {}) do
					if data.religion ~= nil then
						local beliefs = {}

						for i, belief in ipairs(data.religion.beliefs or {}) do
							beliefs[i] = indexes[belief]
						end

						religions[#religions + 1] = { Religion = indexes[data.religion.type], Founder = playerID, Beliefs = beliefs }
					end
				end

				return religions
			end,
		}
	end
end
