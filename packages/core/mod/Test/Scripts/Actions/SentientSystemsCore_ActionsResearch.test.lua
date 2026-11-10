local FakeGame = require("FakeGame")
local Game = require("Game")
local Helpers = require("Helpers")

local Failed, With = Helpers.Failed, Helpers.With

-- Techs for player 0: Mining in research, Sailing to research, Pottery
-- researched, Bronze Working behind Mining, and Writing unrevealed.
local TECHS = {
	current = "TECH_MINING",
	options = {
		{ type = "TECH_MINING", cost = 25, turns = 3 },
		{ type = "TECH_SAILING", cost = 50, turns = 5 },
		{ type = "TECH_POTTERY", cost = 25, turns = 3, researched = true, locked = true },
		{ type = "TECH_BRONZE_WORKING", cost = 80, turns = 8, locked = true, path = { "TECH_MINING", "TECH_BRONZE_WORKING" } },
		{ type = "TECH_WRITING", cost = 50, turns = 5, locked = true, hidden = true },
	},
}

-- Civics for player 0: Mysticism to research, and Theology behind it.
local CIVICS = {
	options = {
		{ type = "CIVIC_MYSTICISM", cost = 50, turns = 5 },
		{ type = "CIVIC_THEOLOGY", cost = 120, turns = 12, locked = true, path = { "CIVIC_MYSTICISM", "CIVIC_THEOLOGY" } },
	},
}

-- Returns an environment with the actions loaded into a fake game that has
-- player 0 with the techs and civics.
local function Load(techs)
	local env = Game.new()

	FakeGame.Install(env, { players = { [0] = { techs = techs or TECHS, civics = CIVICS } } })
	Game.run(env, "Scripts/Actions/SentientSystemsCore_Actions.lua")

	return env
end

-- Returns the request the tree screen sends for the path of types, with the
-- operation, the parameter key, and the insert mode, by their names in
-- PlayerOperations.
local function Request(env, path, operation, parameter, mode)
	local P = env.PlayerOperations
	local indexes = {}

	for i, typeName in ipairs(path) do
		indexes[i] = (env.GameInfo.Technologies[typeName] or env.GameInfo.Civics[typeName]).Index
	end

	return { player = 0, operation = P[operation], parameters = { [P[parameter]] = indexes, [P.PARAM_INSERT_MODE] = P[mode] } }
end

describe("SentientSystems_SetResearch", function()
	it("replaces the queue with a tech the player can research", function()
		local env = Load()

		assert.equal("{\"ok\":true}", env.SentientSystems_SetResearch(0, "TECH_SAILING"))
		assert.same({ Request(env, { "TECH_SAILING" }, "RESEARCH", "PARAM_TECH_TYPE", "VALUE_EXCLUSIVE") }, env.requests)
	end)

	it("sends the path through the prerequisites of a later tech", function()
		local env = Load()

		assert.equal("{\"ok\":true}", env.SentientSystems_SetResearch(0, "TECH_BRONZE_WORKING"))
		assert.same({ Request(env, { "TECH_MINING", "TECH_BRONZE_WORKING" }, "RESEARCH", "PARAM_TECH_TYPE", "VALUE_EXCLUSIVE") }, env.requests)
	end)

	it("adds the path to the end of the queue with append", function()
		local env = Load()

		assert.equal("{\"ok\":true}", env.SentientSystems_SetResearch(0, "TECH_BRONZE_WORKING", true))
		assert.same({ Request(env, { "TECH_MINING", "TECH_BRONZE_WORKING" }, "RESEARCH", "PARAM_TECH_TYPE", "VALUE_APPEND") }, env.requests)
	end)

	it("fails for a tech the player has", function()
		local env = Load()

		assert.equal(Failed("You have TECH_POTTERY already."), env.SentientSystems_SetResearch(0, "TECH_POTTERY"))
		assert.same({}, env.requests)
	end)

	it("fails for a tech the tree doesn't reveal yet", function()
		local env = Load()

		assert.equal(Failed("TECH_WRITING isn't revealed yet. Use the type of a tech the tech tree names."), env.SentientSystems_SetResearch(0, "TECH_WRITING"))
		assert.same({}, env.requests)
	end)

	it("fails when the game finds no path", function()
		local env = Load(With(TECHS, { options = { { type = "TECH_SAILING", cost = 50, turns = 5, path = {} } } }))

		assert.equal(Failed("The game finds no path to TECH_SAILING."), env.SentientSystems_SetResearch(0, "TECH_SAILING"))
		assert.same({}, env.requests)
	end)

	it("fails for a type that is no tech, or no text", function()
		local env = Load()

		assert.equal(Failed("CIVIC_MYSTICISM isn't a tech. Use a type from the techs choice or the tech tree."), env.SentientSystems_SetResearch(0, "CIVIC_MYSTICISM"))
		assert.equal(Failed("nil isn't a tech. Use a type from the techs choice or the tech tree."), env.SentientSystems_SetResearch(0))
	end)

	it("fails for an ID with no player", function()
		assert.equal(Failed("SetResearch failed: no player 3"), Load().SentientSystems_SetResearch(3, "TECH_SAILING"))
	end)
end)

describe("SentientSystems_SetCivic", function()
	it("sends the path through the prerequisites of a civic", function()
		local env = Load()

		assert.equal("{\"ok\":true}", env.SentientSystems_SetCivic(0, "CIVIC_THEOLOGY"))
		assert.same({ Request(env, { "CIVIC_MYSTICISM", "CIVIC_THEOLOGY" }, "PROGRESS_CIVIC", "PARAM_CIVIC_TYPE", "VALUE_EXCLUSIVE") }, env.requests)
	end)

	it("adds the civic to the end of the queue with append", function()
		local env = Load()

		assert.equal("{\"ok\":true}", env.SentientSystems_SetCivic(0, "CIVIC_MYSTICISM", true))
		assert.same({ Request(env, { "CIVIC_MYSTICISM" }, "PROGRESS_CIVIC", "PARAM_CIVIC_TYPE", "VALUE_APPEND") }, env.requests)
	end)
end)
