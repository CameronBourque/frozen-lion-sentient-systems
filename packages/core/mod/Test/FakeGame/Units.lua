-- A player's units. A unit has id, type, x, y, moves, maxMoves, damage, which is 0 when missing,
-- maxDamage, which is 100 when missing, dead, delayedDeath, ready, which IsReadyToSelect returns,
-- hidden, which hides it from other players' IsUnitVisible, as a stealthy unit is, and formation,
-- such as "CORPS_MILITARY_FORMATION", which is standard when missing. experience has points,
-- nextLevel, promotions, and available, a list of the promotions it can pick now. Without it, the
-- unit has no experience. A unit and its promotions get GameInfo rows, which the upkeep pass in
-- FakeGame/Maintenance.lua names and hashes. A player's escaping spy and digging archaeologist are
-- in FakeGame/Spies.lua and Artifacts.lua. UnitManager.CanStartCommand has only the promotion
-- command, with results, as the units state asks for it. The game returns false and no results when
-- the unit can't promote. ctx.Formation(unit, formation) gives a unit option, or its corps or army,
-- for a formation.

return function(env, world, ctx)
	local indexes, AddRow = ctx.indexes, ctx.AddRow

	-- The MilitaryFormationTypes values. The tests don't depend on the game's numbers.
	local MILITARY_FORMATION_TYPES = { STANDARD_MILITARY_FORMATION = 0, CORPS_MILITARY_FORMATION = 1, ARMY_MILITARY_FORMATION = 2 }

	env.MilitaryFormationTypes = MILITARY_FORMATION_TYPES
	env.UnitCommandTypes = { PROMOTE = -1259482049 }
	env.UnitCommandResults = { PROMOTIONS = 827475943 }
	env.UnitManager = {
		CanStartCommand = function(unit, command, testOnly, withResults)
			assert(command == env.UnitCommandTypes.PROMOTE and testOnly == true and withResults == true, "no fake for this command")

			local available = unit.availablePromotions

			if available == nil or #available == 0 then
				return false, nil
			end

			return true, { [env.UnitCommandResults.PROMOTIONS] = available }
		end,
	}

	-- Returns the unit option, or its corps or army, for a formation.
	ctx.Formation = function(unit, formation)
		if formation == MILITARY_FORMATION_TYPES.CORPS_MILITARY_FORMATION then
			return unit.corps
		elseif formation == MILITARY_FORMATION_TYPES.ARMY_MILITARY_FORMATION then
			return unit.army
		end

		return unit
	end

	for _, data in pairs(world.players or {}) do
		for _, unit in ipairs(data.units or {}) do
			AddRow("Units", "UnitType", unit.type)

			if unit.experience ~= nil then
				for _, list in ipairs({ unit.experience.promotions or {}, unit.experience.available or {} }) do
					for _, typeName in ipairs(list) do
						AddRow("UnitPromotions", "UnitPromotionType", typeName)
					end
				end
			end
		end
	end

	ctx.OnUnit(function(unit, data)
		local experience = data.experience

		-- Returns the GameInfo indexes of a list of promotion types.
		local function Indexes(types)
			local list = {}

			for i, typeName in ipairs(types or {}) do
				list[i] = indexes[typeName]
			end

			return list
		end

		-- The available promotions, for the fake UnitManager.CanStartCommand.
		unit.availablePromotions = experience and Indexes(experience.available)
		-- Whether other players' IsUnitVisible hides the unit.
		unit.hidden = data.hidden == true

		function unit.GetExperience()
			if experience == nil then
				return nil
			end

			return {
				GetExperiencePoints = function()
					return experience.points
				end,
				GetExperienceForNextLevel = function()
					return experience.nextLevel
				end,
				GetPromotions = function()
					return Indexes(experience.promotions)
				end,
			}
		end

		function unit.GetMilitaryFormation()
			return MILITARY_FORMATION_TYPES[data.formation or "STANDARD_MILITARY_FORMATION"]
		end

		function unit.GetMovesRemaining()
			return data.moves
		end

		function unit.GetMaxMoves()
			return data.maxMoves
		end

		function unit.GetDamage()
			return data.damage or 0
		end

		function unit.GetMaxDamage()
			return data.maxDamage or 100
		end

		function unit.IsDead()
			return data.dead == true
		end

		function unit.IsDelayedDeath()
			return data.delayedDeath == true
		end

		function unit.IsReadyToSelect()
			return data.ready == true
		end
	end)
end
