-- A player's units. A unit has id, type, x, y, moves, maxMoves, damage, which is 0 when missing,
-- maxDamage, which is 100 when missing, dead, delayedDeath, ready, which IsReadyToSelect returns,
-- hidden, which hides it from other players' IsUnitVisible, as a stealthy unit is, and formation,
-- such as "CORPS_MILITARY_FORMATION", which is standard when missing. experience has points,
-- nextLevel, promotions, and available, a list of the promotions it can pick now. Without it, the
-- unit has no experience. The units' rows are in FakeGame.lua, and a player's escaping spy and
-- digging archaeologist in FakeGame/Spies.lua and Artifacts.lua.

return function(env, world, ctx)
	local indexes = ctx.indexes
	local MILITARY_FORMATION_TYPES = env.MilitaryFormationTypes

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
