-- The victories. world.disabledVictories names the victories that are off, such as
-- VICTORY_DIPLOMATIC = true, which Game.IsVictoryEnabled reports, and world.unwinnable names those
-- that no player can win, which Game.GetVictoryProgressForTeam answers with nil. A player's progress
-- maps each victory type to its progress from 0 to 1, 0 when missing, and its team is its ID unless
-- it has data.team. Its techsResearched is the number of techs it has researched, followers the cities
-- that follow its religion, and points its diplomatic victory points, each 0 when missing. Its
-- tourism, culture, science, faith, military, and score are in FakeGame/TopBar.lua, Research.lua,
-- Income.lua, and Scoreboard.lua. For the science victory, a player's spaceport is "complete" or
-- "building" for the district it has, and projectsAdvanced lists the project types it has
-- launched. A city's projects, with their cost, progress, and prereqTech, are in
-- FakeGame/Production.lua. A city's build queue answers a project it doesn't list with a cost of 1
-- and progress of 0. A player's techs are in Research.lua. With Gathering Storm, a player's
-- lightYears and lightYearsPerTurn are 0 when missing, and world.lightYearsNeeded is 50 when
-- missing.

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

	-- The Spaceport has a row, with a hash, that the build queue's lists of districts skip as one it
	-- doesn't know.
	ctx.AddRow("Districts", "DistrictType", "DISTRICT_SPACEPORT")
	env.GameInfo.Districts["DISTRICT_SPACEPORT"].Hash = ctx.NextHash(3000000, "DISTRICT_SPACEPORT")

	-- The game's science projects have rows, without a prerequisite tech unless a city's project says so.
	for _, project in ipairs({
		"PROJECT_LAUNCH_EARTH_SATELLITE",
		"PROJECT_LAUNCH_MOON_LANDING",
		"PROJECT_LAUNCH_MARS_BASE",
		"PROJECT_LAUNCH_MARS_REACTOR",
		"PROJECT_LAUNCH_MARS_HABITATION",
		"PROJECT_LAUNCH_MARS_HYDROPONICS",
		"PROJECT_LAUNCH_EXOPLANET_EXPEDITION",
	}) do
		ctx.AddRow("Projects", "ProjectType", project)
		env.GameInfo.Projects[project].Hash = ctx.NextHash(3000000, project)
	end

	-- A city's build queue answers a science project it doesn't list with a cost of 1 and progress of 0.
	ctx.OnCity(function(city, data)
		local GetBuildQueue = city.GetBuildQueue

		function city.GetBuildQueue()
			local queue = GetBuildQueue()
			local GetProjectCost, GetProjectProgress = queue.GetProjectCost, queue.GetProjectProgress

			local function Lists(index)
				for _, project in ipairs((data.options or {}).projects or {}) do
					if ctx.indexes[project.type] == index then
						return true
					end
				end

				return false
			end

			function queue.GetProjectCost(self, index)
				return Lists(index) and GetProjectCost(self, index) or 1
			end

			function queue.GetProjectProgress(self, index)
				return Lists(index) and GetProjectProgress(self, index) or 0
			end

			return queue
		end
	end)

	ctx.OnPlayer(function(player, data, id)
		local GetStats, GetDistricts = player.GetStats, player.GetDistricts

		-- The player's districts that the science victory looks at: the Spaceport it has, if any.
		function player.GetDistricts()
			local districts = GetDistricts()

			function districts.Members()
				local list = {}

				if data.spaceport ~= nil then
					list[1] = {
						IsComplete = function()
							return data.spaceport == "complete"
						end,
						GetType = function()
							return env.GameInfo.Districts["DISTRICT_SPACEPORT"].Index
						end,
					}
				end

				return ipairs(list)
			end

			return districts
		end

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

			function stats.GetNumProjectsAdvanced(_, index)
				for _, project in ipairs(data.projectsAdvanced or {}) do
					if env.GameInfo.Projects[project].Index == index then
						return 1
					end
				end

				return 0
			end

			if world.expansion2 then
				function stats.GetScienceVictoryPoints()
					return data.lightYears or 0
				end

				function stats.GetScienceVictoryPointsPerTurn()
					return data.lightYearsPerTurn or 0
				end

				function stats.GetScienceVictoryPointsTotalNeeded()
					return world.lightYearsNeeded or 50
				end
			end

			return stats
		end
	end)
end
