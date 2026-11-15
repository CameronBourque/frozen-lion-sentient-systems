-- Rock bands, in Gathering Storm. Fakes GameInfo.Unit_RockbandResults_XP2 from
-- world.rockBandResults, in index order from 0, and a unit's GetRockBand from
-- its rockBand data, which says whether it is at its most promotions or level.

return function(env, world, ctx)
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
