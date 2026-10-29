-- The victories. world.disabledVictories names the victories that are off, such as
-- VICTORY_DIPLOMATIC = true, which Game.IsVictoryEnabled reports, and world.unwinnable names those
-- that no player can win, which Game.GetVictoryProgressForTeam answers with nil. A player's progress
-- maps each victory type to its progress from 0 to 1, 0 when missing, and its team is its ID unless
-- it has data.team. Its techsResearched is the number of techs it has researched, followers the cities
-- that follow its religion, and points its diplomatic victory points, each 0 when missing. Its
-- tourism, culture, science, faith, military, and score are in FakeGame/TopBar.lua, Research.lua,
-- Income.lua, and Scoreboard.lua.

return function(env, world, ctx)
	local disabled, unwinnable = world.disabledVictories or {}, world.unwinnable or {}

	env.GlobalParameters.DIPLOMATIC_VICTORY_POINTS_REQUIRED = 20

	env.Game.IsVictoryEnabled = function(victory)
		return disabled[victory] ~= true
	end

	env.Game.GetVictoryProgressForTeam = function(victory, team)
		if unwinnable[victory] then
			return nil
		end

		for id, data in pairs(world.players or {}) do
			if (data.team or id) == team then
				return (data.progress or {})[victory] or 0
			end
		end
	end

	ctx.OnPlayer(function(player, data, id)
		local GetStats = player.GetStats

		function player.GetTeam()
			return data.team or id
		end

		function player.GetStats()
			local stats = GetStats()

			function stats.GetNumTechsResearched()
				return data.techsResearched or 0
			end

			function stats.GetNumCitiesFollowingReligion()
				return data.followers or 0
			end

			function stats.GetDiplomaticVictoryPoints()
				return data.points or 0
			end

			return stats
		end
	end)
end
