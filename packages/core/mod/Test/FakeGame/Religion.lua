-- Religion. Fakes the ruleset's beliefs, a player's pantheon and religion, and
-- the religions in a city. FakeGame/Stores.lua holds the faith store.

return function(env, world, ctx)
	local AddRow, indexes = ctx.AddRow, ctx.indexes

	env.GameInfo.Beliefs = ctx.TypedRows({}, "BeliefType")
	env.GameInfo.Religions = ctx.TypedRows({}, "ReligionType")

	for _, belief in ipairs(world.beliefs or {}) do
		AddRow("Beliefs", "BeliefType", belief.type)

		local row = env.GameInfo.Beliefs[indexes[belief.type]]

		row.Hash = ctx.NextHash(5000000, belief.type)
		row.BeliefClassType = belief.class or "BELIEF_CLASS_PANTHEON"
		row.Description = belief.description
		row.taken = belief.taken
		row.tooMany = belief.tooMany
	end

	for _, religion in ipairs(world.religions or {}) do
		AddRow("Religions", "ReligionType", religion.type)

		local row = env.GameInfo.Religions[indexes[religion.type]]

		row.Pantheon = religion.pantheon == true
		row.RequiresCustomName = religion.customName == true
		row.founded = religion.founded
	end

	-- Each religion that a player founded or a city holds gets a row, with its
	-- name, and each of a founded religion's beliefs a belief row.
	for _, data in pairs(world.players or {}) do
		local religions = { data.religion }

		for _, city in ipairs(data.cities or {}) do
			for _, present in ipairs(city.religions or {}) do
				-- The pantheon row sits at index 0. An entry with no type is
				-- the citizens with no religion.
				AddRow("Religions", "ReligionType", "RELIGION_PANTHEON")

				if present.type then
					religions[#religions + 1] = present
				end
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

	-- A unit with a religion, a type, gets a row for it, after the pantheon row
	-- that the game keeps at index 0.
	for _, data in pairs(world.players or {}) do
		for _, unit in ipairs(data.units or {}) do
			if unit.religion then
				AddRow("Religions", "ReligionType", "RELIGION_PANTHEON")
				AddRow("Religions", "ReligionType", unit.religion)
			end
		end
	end

	ctx.OnUnit(function(unit, data)
		function unit.GetReligionType()
			return data.religion and indexes[data.religion] or -1
		end

		function unit.GetReligiousStrength()
			return data.religiousStrength or 0
		end

		function unit.GetSpreadCharges()
			return data.spreadCharges or 0
		end

		function unit.GetReligiousHealCharges()
			return data.healCharges or 0
		end
	end)

	ctx.OnCity(function(city, data)
		city.GetReligion = function()
			return {
				GetMajorityReligion = function()
					return data.majority and indexes[data.majority] or -1
				end,
				GetReligionsInCity = function()
					local present = {}

					for i, religion in ipairs(data.religions or {}) do
						present[i] = { Religion = indexes[religion.type] or -1, Followers = religion.followers, Pressure = religion.totalPressure or 0 }
					end

					return present
				end,
				GetNextReligion = function()
					return data.converting and indexes[data.converting.type] or -1
				end,
				GetTurnsToNextReligion = function()
					return data.converting and data.converting.turns or 0
				end,
				GetPressureFromCity = function()
					return data.outwardPressure or 0
				end,
				GetTotalPressureOnCity = function(_, religionIndex)
					for _, religion in ipairs(data.religions or {}) do
						if indexes[religion.type] == religionIndex then
							return religion.pressure or 0
						end
					end

					return 0
				end,
			}
		end
	end)

	ctx.OnPlayer(function(player, data, id)
		local GetReligion = player.GetReligion

		function player.GetReligion()
			local religion = GetReligion()

			function religion.GetPantheon()
				return data.pantheon and indexes[data.pantheon] or -1
			end

			function religion.CanCreatePantheon()
				return data.canCreatePantheon == true
			end

			-- The religion the player founded, from data.religion, with type
			-- and holyCity, a city ID. The beliefs earned come from
			-- data.beliefsEarned, the count of its beliefs when missing.
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

	-- Whether any player's pantheon or religion holds a belief, from each
	-- belief's taken.
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
