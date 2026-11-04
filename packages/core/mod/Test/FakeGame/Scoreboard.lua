-- Scores. Fakes a player's score, its categories, and its military strength,
-- with the game's scoring categories.

local CATEGORIES = {
	{ "CATEGORY_CIVICS", 1 },
	{ "CATEGORY_EMPIRE", 1 },
	{ "CATEGORY_GREAT_PEOPLE", 1 },
	{ "CATEGORY_RELIGION", 1 },
	{ "CATEGORY_TECH", 1 },
	{ "CATEGORY_WONDER", 1 },
	{ "CATEGORY_TRADE", 0 },
	{ "CATEGORY_ERA_SCORE", 1 },
}

return function(env, world, ctx)
	env.GameInfo.ScoringCategories = ctx.TypedRows({}, "CategoryType")

	for index, row in ipairs(CATEGORIES) do
		env.GameInfo.ScoringCategories[index - 1] = {
			Index = index - 1,
			CategoryType = row[1],
			Name = "LOC_" .. row[1] .. "_NAME",
			Multiplier = row[2],
		}
	end

	ctx.OnPlayer(function(player, data)
		local GetStats = player.GetStats

		function player.GetScore()
			return data.score or 0
		end

		function player.GetCategoryScore(_, index)
			return (data.categories or {})[CATEGORIES[index + 1][1]] or 0
		end

		function player.GetStats()
			local stats = GetStats()

			function stats.GetMilitaryStrengthWithoutTreasury()
				return data.military or 0
			end

			return stats
		end
	end)
end
