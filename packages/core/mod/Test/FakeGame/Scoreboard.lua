-- Scores. A player's score is its score, and its categories maps a scoring category's type to its
-- points, such as CATEGORY_CIVICS = 3, each 0 when missing. Its military is its military
-- strength without the treasury, 0 when missing. GameInfo.ScoringCategories has the game's
-- categories, each with a CategoryType, Name, and Multiplier. CATEGORY_TRADE has no multiplier, so the
-- Score tab leaves it out. world.noDiplomaticVictory turns that victory off, which Game.IsVictoryEnabled
-- reports. Culture, science, gold, faith, and favor are in FakeGame/TopBar.lua, Research.lua, and
-- Stores.lua.

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

	env.Game.IsVictoryEnabled = function(victory)
		return victory ~= "VICTORY_DIPLOMATIC" or world.noDiplomaticVictory ~= true
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
