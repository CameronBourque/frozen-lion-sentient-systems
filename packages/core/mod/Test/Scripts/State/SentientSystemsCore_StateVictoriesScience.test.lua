local FakeGame = require("FakeGame")
local Game = require("Game")

local GS_PROJECTS = {
	{ type = "PROJECT_LAUNCH_EARTH_SATELLITE", prereqTech = "TECH_ROCKETRY" },
	{ type = "PROJECT_LAUNCH_MOON_LANDING", prereqTech = "TECH_SATELLITES" },
	{ type = "PROJECT_LAUNCH_MARS_BASE", prereqTech = "TECH_NANOTECHNOLOGY" },
	{ type = "PROJECT_LAUNCH_EXOPLANET_EXPEDITION", prereqTech = "TECH_SMART_MATERIALS" },
}

local BASE_PROJECTS = {
	{ type = "PROJECT_LAUNCH_EARTH_SATELLITE", prereqTech = "TECH_ROCKETRY" },
	{ type = "PROJECT_LAUNCH_MOON_LANDING", prereqTech = "TECH_SATELLITES" },
	{ type = "PROJECT_LAUNCH_MARS_REACTOR", prereqTech = "TECH_NANOTECHNOLOGY" },
	{ type = "PROJECT_LAUNCH_MARS_HABITATION" },
	{ type = "PROJECT_LAUNCH_MARS_HYDROPONICS" },
}

-- Returns a city that knows the projects, each at cost 400 and with the progress that progress gives
-- by project type, 0 when missing.
local function City(id, projects, progress)
	local options = {}

	for i, project in ipairs(projects) do
		options[i] = { type = project.type, cost = 400, turns = 1, progress = progress[project.type] or 0, prereqTech = project.prereqTech }
	end

	return { id = id, name = "LOC_X", x = id, y = 1, population = 1, options = { projects = options } }
end

local function Techs(researched)
	local options = {}

	for _, tech in ipairs({ "TECH_ROCKETRY", "TECH_SATELLITES", "TECH_NANOTECHNOLOGY", "TECH_SMART_MATERIALS" }) do
		options[#options + 1] = { type = tech, cost = 1, turns = 1, researched = researched[tech] == true }
	end

	return { options = options }
end

-- Returns the science entry of player 0 in a world where player 0 has these cities and fields.
local function ScienceOf(projects, player, world, cities)
	local env = Game.new()

	player.techs = player.techs or Techs({})
	player.cities = cities or { City(65536, projects, {}) }
	world = world or {}
	world.players = { [0] = player }
	FakeGame.Install(env, world)
	Game.run(env, "Scripts/State/SentientSystemsCore_State.lua")

	return env.SentientSystems_GetState(0):match("\"science\":(%b[])")
end

describe("SentientSystems_GetScienceDetails", function()
	it("lists each stage with its tasks, the Spaceport first, and the progress over the cities that have it", function()
		local json = ScienceOf(GS_PROJECTS, {
			spaceport = "complete",
			techs = Techs({ TECH_ROCKETRY = true }),
		}, { expansion2 = true }, {
			City(65536, GS_PROJECTS, { PROJECT_LAUNCH_EARTH_SATELLITE = 100 }),
			City(65537, GS_PROJECTS, {}),
		})

		assert.truthy(json:find(
			"\"stages\":[{\"done\":false,\"progress\":0.25,\"tasks\":[{\"done\":true,\"kind\":\"district\",\"type\":\"DISTRICT_SPACEPORT\"},"
				.. "{\"done\":true,\"kind\":\"tech\",\"type\":\"TECH_ROCKETRY\"},"
				.. "{\"done\":false,\"kind\":\"project\",\"type\":\"PROJECT_LAUNCH_EARTH_SATELLITE\"}]},",
			1,
			true
		))
		assert.truthy(json:find(
			"{\"done\":false,\"progress\":0,\"tasks\":[{\"done\":false,\"kind\":\"tech\",\"type\":\"TECH_SATELLITES\"},"
				.. "{\"done\":false,\"kind\":\"project\",\"type\":\"PROJECT_LAUNCH_MOON_LANDING\"}]},",
			1,
			true
		))
	end)

	it("marks a stage done when its projects are finished, and a launched project as finished", function()
		local json = ScienceOf(GS_PROJECTS, {
			spaceport = "building",
			techs = Techs({ TECH_ROCKETRY = true, TECH_SATELLITES = true }),
			projectsAdvanced = { "PROJECT_LAUNCH_EARTH_SATELLITE" },
		}, { expansion2 = true }, { City(65536, GS_PROJECTS, { PROJECT_LAUNCH_MOON_LANDING = 400 }) })

		assert.truthy(json:find("\"stages\":[{\"done\":true,\"progress\":1,\"tasks\":[{\"done\":false,\"kind\":\"district\"", 1, true))
		assert.truthy(json:find(
			"{\"done\":true,\"progress\":1,\"tasks\":[{\"done\":true,\"kind\":\"tech\",\"type\":\"TECH_SATELLITES\"},"
				.. "{\"done\":true,\"kind\":\"project\",\"type\":\"PROJECT_LAUNCH_MOON_LANDING\"}]},",
			1,
			true
		))
	end)

	it("counts every city for the third stage, including those with no progress", function()
		local json = ScienceOf(GS_PROJECTS, { spaceport = "none" }, { expansion2 = true }, {
			City(65536, GS_PROJECTS, { PROJECT_LAUNCH_MARS_BASE = 100 }),
			City(65537, GS_PROJECTS, {}),
		})

		assert.truthy(json:find("{\"done\":false,\"progress\":0.125,\"tasks\":[{\"done\":false,\"kind\":\"tech\",\"type\":\"TECH_NANOTECHNOLOGY\"}", 1, true))
	end)

	it("has no progress for a player with no cities", function()
		local json = ScienceOf(GS_PROJECTS, {}, { expansion2 = true }, {})

		assert.truthy(json:find("\"stages\":[{\"done\":false,\"progress\":0,", 1, true))
	end)

	it("adds the light years once the expedition is launched, never beyond what is needed", function()
		local player = { projectsAdvanced = { "PROJECT_LAUNCH_EXOPLANET_EXPEDITION" }, lightYears = 60, lightYearsPerTurn = 2.25 }
		local json = ScienceOf(GS_PROJECTS, player, { expansion2 = true })

		assert.truthy(json:find("\"lightYears\":{\"current\":50,\"needed\":50,\"perTurn\":2.3}", 1, true))
		assert.is_nil(ScienceOf(GS_PROJECTS, {}, { expansion2 = true }):find("lightYears", 1, true))
	end)

	it("has three stages in the base game, the last with three projects, and no light years", function()
		local json = ScienceOf(BASE_PROJECTS, { projectsAdvanced = { "PROJECT_LAUNCH_MARS_HABITATION" } }, nil, {
			City(65536, BASE_PROJECTS, { PROJECT_LAUNCH_MARS_REACTOR = 200 }),
		})

		assert.truthy(json:find(
			"{\"done\":false,\"progress\":0.5,\"tasks\":[{\"done\":false,\"kind\":\"tech\",\"type\":\"TECH_NANOTECHNOLOGY\"},"
				.. "{\"done\":false,\"kind\":\"project\",\"type\":\"PROJECT_LAUNCH_MARS_REACTOR\"},"
				.. "{\"done\":true,\"kind\":\"project\",\"type\":\"PROJECT_LAUNCH_MARS_HABITATION\"},"
				.. "{\"done\":false,\"kind\":\"project\",\"type\":\"PROJECT_LAUNCH_MARS_HYDROPONICS\"}]}",
			1,
			true
		))
		assert.is_nil(json:find("EXOPLANET", 1, true))
	end)
end)
