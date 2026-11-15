-- Rock bands, in Gathering Storm. Fakes the concert results from
-- world.rockBandResults, the rock band's Units_XP2 row, and a unit's
-- GetRockBand from its rockBand data.

return function(env, world, ctx)
	-- The game has the row only with the expansion.
	if world.expansion2 then
		env.GameInfo.Units_XP2 = { UNIT_ROCK_BAND = { UnitType = "UNIT_ROCK_BAND", TourismBombPossible = true } }
	end

	env.GameInfo.Unit_RockbandResults_XP2 = {}

	for i, row in ipairs(world.rockBandResults or {}) do
		env.GameInfo.Unit_RockbandResults_XP2[i - 1] = row
	end

	ctx.OnUnit(function(unit, data)
		if data.rockBand == nil then
			return
		end

		function unit.GetRockBand()
			return {
				IsMaxPromotions = function()
					return data.rockBand.maxPromotions == true
				end,
				IsMaxLevel = function()
					return data.rockBand.maxLevel == true
				end,
			}
		end
	end)
end
