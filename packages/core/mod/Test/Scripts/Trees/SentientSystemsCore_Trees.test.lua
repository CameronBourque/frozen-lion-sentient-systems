local FakeGame = require("FakeGame")
local Game = require("Game")

local POTTERY = { type = "TECH_POTTERY", cost = 25, turns = 4, researched = true, locked = true, unlocks = { "BUILDING_GRANARY" } }
local IRRIGATION = {
	type = "TECH_IRRIGATION",
	cost = 50,
	turns = 8,
	prerequisites = { "TECH_POTTERY" },
	boost = { percent = 40, trigger = "Farm a resource.", triggered = false },
	unlocks = { "IMPROVEMENT_PLANTATION" },
}
local CURRENCY = { type = "TECH_CURRENCY", era = "ERA_CLASSICAL", cost = 120, turns = 20, prerequisites = { "TECH_IRRIGATION" }, locked = true }

-- Returns an environment with the trees script loaded into a fake game built from world.
local function Load(world)
	local env = Game.new()

	FakeGame.Install(env, world)
	Game.run(env, "Scripts/Trees/SentientSystemsCore_Trees.lua")

	return env
end

-- Returns the nodes of player 0's tech tree as JSON, for the given techs.
local function NodesWith(techs)
	return Load({ players = { [0] = { techs = techs } } }).SentientSystems_GetTechTree(0):match("\"nodes\":(%b[])")
end

-- Returns a copy of tech with the fields in changes.
local function With(tech, changes)
	local copy = {}

	for key, value in pairs(tech) do
		copy[key] = value
	end

	for key, value in pairs(changes) do
		copy[key] = value
	end

	return copy
end

describe("SentientSystems_GetTechTree", function()
	it("lists every node with its era, status, cost, turns, prerequisites, boost, and unlocks", function()
		assert.equal(
			"[{\"cost\":25,\"era\":\"ERA_ANCIENT\",\"prerequisites\":[],\"status\":\"researched\",\"type\":\"TECH_POTTERY\",\"unlocks\":[\"BUILDING_GRANARY\"]},"
				.. "{\"boost\":{\"percent\":40,\"trigger\":\"Farm a resource.\",\"triggered\":false},\"cost\":50,\"era\":\"ERA_ANCIENT\","
				.. "\"prerequisites\":[\"TECH_POTTERY\"],\"status\":\"ready\",\"turns\":8,\"type\":\"TECH_IRRIGATION\",\"unlocks\":[\"IMPROVEMENT_PLANTATION\"]},"
				.. "{\"cost\":120,\"era\":\"ERA_CLASSICAL\",\"prerequisites\":[\"TECH_IRRIGATION\"],\"status\":\"blocked\",\"turns\":20,\"type\":\"TECH_CURRENCY\",\"unlocks\":[]}]",
			NodesWith({ options = { POTTERY, IRRIGATION, CURRENCY } })
		)
	end)

	it("gives the node in research the turns from GetTurnsLeft, and its progress", function()
		local nodes = NodesWith({ current = "TECH_IRRIGATION", turnsLeft = 3, options = { POTTERY, With(IRRIGATION, { progress = 30 }) } })

		assert.truthy(nodes:find("\"progress\":30,\"status\":\"current\",\"turns\":3,", 1, true))
	end)

	it("leaves out the boost, progress, and advisor's pick of a researched node", function()
		local nodes = NodesWith({ options = { With(IRRIGATION, { researched = true, locked = true, progress = 50, recommended = true }) } })

		assert.is_nil(nodes:find("boost", 1, true))
		assert.is_nil(nodes:find("progress", 1, true))
		assert.is_nil(nodes:find("recommended", 1, true))
	end)

	it("leaves out turns that aren't above 0, as before a city makes science", function()
		assert.is_nil(NodesWith({ options = { With(IRRIGATION, { turns = -1 }) } }):find("turns", 1, true))
	end)

	it("shows an unrevealed node as a numbered placeholder, linked to the nodes around it", function()
		local nodes = NodesWith({ options = {
			POTTERY,
			With(IRRIGATION, { hidden = true, progress = 5 }),
			With(CURRENCY, { hidden = true }),
		} })

		assert.truthy(nodes:find("{\"era\":\"ERA_ANCIENT\",\"prerequisites\":[\"TECH_POTTERY\"],\"progress\":5,\"status\":\"ready\",\"turns\":8,\"type\":\"?1\"}", 1, true))
		assert.truthy(nodes:find("{\"era\":\"ERA_CLASSICAL\",\"prerequisites\":[\"?1\"],\"status\":\"blocked\",\"turns\":20,\"type\":\"?2\"}", 1, true))
		assert.is_nil(nodes:find("TECH_IRRIGATION", 1, true))
		assert.is_nil(nodes:find("Farm a resource.", 1, true))
	end)

	it("lists the player and each player they have met, with their researched count and latest era", function()
		local env = Load({ players = {
			[0] = { met = { 2 }, techs = { options = { POTTERY, IRRIGATION, With(CURRENCY, { researched = true }) } } },
			[1] = {},
			[2] = { techs = { options = { POTTERY } } },
		} })

		assert.truthy(env.SentientSystems_GetTechTree(0):find(
			"\"players\":[{\"era\":\"ERA_CLASSICAL\",\"player\":0,\"researched\":2},{\"era\":\"ERA_ANCIENT\",\"player\":2,\"researched\":1}]",
			1,
			true
		))
	end)

	it("leaves out the era of a player who has researched nothing", function()
		local env = Load({ players = { [0] = { techs = { options = { IRRIGATION } } } } })

		assert.truthy(env.SentientSystems_GetTechTree(0):find("\"players\":[{\"player\":0,\"researched\":0}]", 1, true))
	end)

	it("raises an error for an ID with no player", function()
		local env = Load({ players = { [0] = {} } })

		assert.has_error(function()
			env.SentientSystems_GetTechTree(5)
		end, "no player 5")
	end)

	it("loads the JSON encoder and the research reader without an ERROR line, so the bridge can stash the tree", function()
		local env = Load({ players = { [0] = { techs = { options = { POTTERY } } } } })

		assert.same({}, env.printed)
		assert.equal(1, env.SentientSystems_Stash(env.SentientSystems_GetTechTree(0)))
	end)
end)
