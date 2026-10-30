-- The science part of the victories section of the state: a player's stages toward the science
-- victory and the tasks of each, as the Science tab of World Rankings shows them. The numbers follow
-- PopulateScienceInstance and GetTooltipForScienceProject in WorldRankings.lua and
-- WorldRankings_Expansion2.lua. SentientSystemsCore_StateVictories.lua loads this file. Example:
-- SentientSystems_GetScienceDetails(player, other) returns a table that encodes as '{"stages":
-- [{"done":false,"progress":0.4,"tasks":[{"done":true,"kind":"district","type":"DISTRICT_SPACEPORT"},
-- {"done":false,"kind":"tech","type":"TECH_SATELLITES"},{"done":false,"kind":"project","type":
-- "PROJECT_LAUNCH_EARTH_SATELLITE"}]}]}', on one line.

-- The projects of each stage. Gathering Storm has four stages of one project, and the base game three.
local function GetStageProjects()
	local stages = {
		{ "PROJECT_LAUNCH_EARTH_SATELLITE" },
		{ "PROJECT_LAUNCH_MOON_LANDING" },
	}

	if SentientSystems_HasExpansion2() then
		stages[3] = { "PROJECT_LAUNCH_MARS_BASE" }
		stages[4] = { "PROJECT_LAUNCH_EXOPLANET_EXPEDITION" }
	else
		stages[3] = { "PROJECT_LAUNCH_MARS_REACTOR", "PROJECT_LAUNCH_MARS_HABITATION", "PROJECT_LAUNCH_MARS_HYDROPONICS" }
	end

	return stages
end

-- Rounds to the nearest thousandth, which the game's single precision floats leave long.
local function RoundProgress(progress)
	return math.floor(progress * 1000 + 0.5) / 1000
end

local function RoundNearest(number)
	return math.floor(number * 10 + 0.5) / 10
end

-- Returns whether the player has a finished Spaceport.
local function HasSpaceport(other)
	local spaceport = GameInfo.Districts["DISTRICT_SPACEPORT"].Index

	for _, district in other:GetDistricts():Members() do
		if district:IsComplete() and district:GetType() == spaceport then
			return true
		end
	end

	return false
end

-- Returns the progress of a stage over the player's cities, its total cost, and which of its projects
-- are finished, by the last city, as the tab counts them. The first two stages count only a city that
-- has progress.
local function GetStageProgress(other, projects, counted)
	local stats = other:GetStats()
	local total, progress, finished = 0, 0, {}

	for _, city in other:GetCities():Members() do
		local queue = city:GetBuildQueue()

		for i, projectType in ipairs(projects) do
			local index = GameInfo.Projects[projectType].Index
			local cost = queue:GetProjectCost(index)
			local done = cost

			if stats:GetNumProjectsAdvanced(index) == 0 then
				done = queue:GetProjectProgress(index)
			end

			finished[i] = false

			if counted or done ~= 0 then
				total = total + cost
				progress = progress + done
				finished[i] = done == cost
			end
		end
	end

	return progress, total, finished
end

-- Returns the tasks of a stage, in the tooltip's order: the Spaceport for the first stage, then for
-- each project the tech it needs, if any, and the project.
local function GetTasks(other, projects, finished, withSpaceport)
	local tasks = {}
	local techs = other:GetTechs()

	if withSpaceport then
		tasks[1] = { kind = "district", type = "DISTRICT_SPACEPORT", done = HasSpaceport(other) }
	end

	for i, projectType in ipairs(projects) do
		local tech = GameInfo.Projects[projectType].PrereqTech

		if tech ~= nil then
			tasks[#tasks + 1] = { kind = "tech", type = tech, done = techs:HasTech(GameInfo.Technologies[tech].Index) }
		end

		tasks[#tasks + 1] = { kind = "project", type = projectType, done = finished[i] == true }
	end

	return tasks
end

-- Returns the player's stages, each with progress, from 0 to 1, done, and tasks, each with kind, such
-- as project, type, and done. With Gathering Storm, once the player has launched the exoplanet
-- expedition, lightYears has the light years travelled, the needed, and perTurn. needed is the
-- viewing player's, as the tab reads it.
function SentientSystems_GetScienceDetails(player, other)
	local details = { stages = {} }
	local stats = other:GetStats()

	for i, projects in ipairs(GetStageProjects()) do
		local progress, total, finished = GetStageProgress(other, projects, i > 2)

		details.stages[i] = {
			progress = total == 0 and 0 or RoundProgress(progress / total),
			done = total ~= 0 and progress == total,
			tasks = GetTasks(other, projects, finished, i == 1),
		}
	end

	if SentientSystems_HasExpansion2() and details.stages[4].done then
		local needed = player:GetStats():GetScienceVictoryPointsTotalNeeded()

		details.lightYears = {
			current = RoundNearest(math.min(stats:GetScienceVictoryPoints(), needed)),
			needed = needed,
			perTurn = RoundNearest(stats:GetScienceVictoryPointsPerTurn()),
		}
	end

	return details
end
