-- Great people. Fakes the great people on offer, a player's points toward each
-- class, and a unit's class. FakeGame/Capabilities.lua turns off great people
-- capabilities.

return function(env, world, ctx)
	local AddRow, indexes, YIELD_TYPES = ctx.AddRow, ctx.indexes, ctx.YIELD_TYPES

	env.GameInfo.GreatPersonClasses = {}
	env.GameInfo.GreatPersonIndividuals = {}


	-- Each great person on offer gets rows for its class, era, and individual.
	for _, person in ipairs(world.greatPeople or {}) do
		AddRow("GreatPersonClasses", "GreatPersonClassType", person.class)
		AddRow("Eras", "EraType", person.era)
		AddRow("GreatPersonIndividuals", "GreatPersonIndividualType", person.type)

		local row = env.GameInfo.GreatPersonIndividuals[indexes[person.type]]

		row.Name = person.name or person.type
		row.ActionCharges = person.charges or 0
	end

	-- A unit with greatPerson set, a class name, is a great person of it.
	for _, data in pairs(world.players or {}) do
		for _, unit in ipairs(data.units or {}) do
			if unit.greatPerson then
				AddRow("GreatPersonClasses", "GreatPersonClassType", unit.greatPerson)
			end
		end
	end

	ctx.OnUnit(function(unit, data)
		function unit.GetGreatPerson()
			if data.greatPerson == nil then
				return nil
			end

			return {
				GetClass = function()
					return indexes[data.greatPerson]
				end,
			}
		end
	end)

	ctx.OnPlayer(function(player, data)
		player.GetGreatPeoplePoints = function()
			local function Points(classIndex)
				return (data.greatPeoplePoints or {})[env.GameInfo.GreatPersonClasses[classIndex].GreatPersonClassType] or {}
			end

			return {
				GetPointsTotal = function(_, classIndex)
					return Points(classIndex).points or 0
				end,
				GetPointsPerTurn = function(_, classIndex)
					return Points(classIndex).perTurn or 0
				end,
			}
		end
	end)

	env.Game.GetGreatPeople = function()
		local byIndex = {}

		for _, person in ipairs(world.greatPeople or {}) do
			byIndex[indexes[person.type]] = person
		end

		local function Patronage(index, yield)
			return byIndex[index][yield == YIELD_TYPES.GOLD and "gold" or "faith"] or {}
		end

		return {
			GetTimeline = function()
				local timeline = {}

				for i, person in ipairs(world.greatPeople or {}) do
					local passive, action = person.passive or {}, person.action or {}

					timeline[i] = {
						Individual = (not person.claimed) and indexes[person.type] or nil,
						Class = indexes[person.class],
						Era = indexes[person.era],
						Cost = person.cost,
						PassiveNameText = passive.name,
						PassiveEffectText = passive.effect,
						ActionNameText = action.name,
						ActionUsageText = action.usage,
						ActionEffectText = action.effect,
					}
				end

				return timeline
			end,
			CanRecruitPerson = function(_, _, index)
				return byIndex[index].canRecruit == true
			end,
			CanRejectPerson = function(_, _, index)
				return byIndex[index].passCost ~= nil
			end,
			GetRejectCost = function(_, _, index)
				return byIndex[index].passCost
			end,
			CanPatronizePerson = function(_, _, index, yield)
				return Patronage(index, yield).can == true
			end,
			GetPatronizeCost = function(_, _, index, yield)
				return Patronage(index, yield).cost or 2147483647
			end,
			GetEarnConditionsText = function(_, _, index)
				return byIndex[index].cantEarn or ""
			end,
		}
	end
end
