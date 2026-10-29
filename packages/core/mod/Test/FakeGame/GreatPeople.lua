-- Great people. world.greatPeople lists the great people on offer, each with class, type, name, era, cost,
-- charges, passive and action, each with the text the timeline gives, canRecruit, passCost, there
-- when the player can pass, gold and faith, each with cost and can, cantEarn, and claimed, true for a
-- class whose great person is taken. A player's greatPeoplePoints maps a class type to its points
-- and perTurn. world.offCapabilities, which turns off great people capabilities, is in FakeGame.lua.

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

	ctx.OnPlayer(function(player, data)
		-- The player's points toward each class of great person, from data.greatPeoplePoints by class
		-- type, each with points and perTurn.
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

	-- The great people on offer, from world.greatPeople, by the GameInfo index of each individual.
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
