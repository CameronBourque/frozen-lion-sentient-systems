local FakeGame = require("FakeGame")
local Game = require("Game")
local Helpers = require("Helpers")

local Failed, With = Helpers.Failed, Helpers.With

-- Techs for player 0: Mining in research, Sailing to research, Pottery
-- researched, and Bronze Working locked behind Mining.
local TECHS = {
	current = "TECH_MINING",
	options = {
		{ type = "TECH_MINING", cost = 25, turns = 3 },
		{ type = "TECH_SAILING", cost = 50, turns = 5 },
		{ type = "TECH_POTTERY", cost = 25, turns = 3, researched = true, locked = true },
		{ type = "TECH_BRONZE_WORKING", cost = 80, turns = 8, locked = true },
	},
}

-- Civics for player 0: Mysticism to research, and Theology locked.
local CIVICS = {
	options = {
		{ type = "CIVIC_MYSTICISM", cost = 50, turns = 5 },
		{ type = "CIVIC_THEOLOGY", cost = 120, turns = 12, locked = true },
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

-- Returns the request the chooser sends for the row, with the operation and the
-- parameter key, by their names in PlayerOperations.
local function Request(env, row, operation, parameter)
	local P = env.PlayerOperations

	return { player = 0, operation = P[operation], parameters = { [P[parameter]] = row.Hash, [P.PARAM_INSERT_MODE] = P.VALUE_EXCLUSIVE } }
end

describe("SentientSystems_SetResearch", function()
	it("sends the chooser's request for a tech the player can research", function()
		local env = Load()

		assert.equal("{\"ok\":true}", env.SentientSystems_SetResearch(0, "TECH_SAILING"))
		assert.same({ Request(env, env.GameInfo.Technologies.TECH_SAILING, "RESEARCH", "PARAM_TECH_TYPE") }, env.requests)
	end)

	it("takes the tech in research even when CanResearch refuses it", function()
		local env = Load(With(TECHS, { current = "TECH_BRONZE_WORKING" }))

		assert.equal("{\"ok\":true}", env.SentientSystems_SetResearch(0, "TECH_BRONZE_WORKING"))
	end)

	it("fails for a tech the player has", function()
		local env = Load()

		assert.equal(Failed("You have TECH_POTTERY already."), env.SentientSystems_SetResearch(0, "TECH_POTTERY"))
		assert.same({}, env.requests)
	end)

	it("fails for a tech the player can't research yet, and points at the choice", function()
		local env = Load()

		assert.equal(Failed("TECH_BRONZE_WORKING isn't one of the techs you can research now. Use the type of an option of the techs choice."), env.SentientSystems_SetResearch(0, "TECH_BRONZE_WORKING"))
		assert.same({}, env.requests)
	end)

	it("fails for a type that is no tech, or no text", function()
		local env = Load()

		assert.equal(Failed("CIVIC_MYSTICISM isn't a tech. Use the type of an option of the techs choice."), env.SentientSystems_SetResearch(0, "CIVIC_MYSTICISM"))
		assert.equal(Failed("nil isn't a tech. Use the type of an option of the techs choice."), env.SentientSystems_SetResearch(0))
	end)

	it("fails for an ID with no player", function()
		assert.equal(Failed("SetResearch failed: no player 3"), Load().SentientSystems_SetResearch(3, "TECH_SAILING"))
	end)
end)

describe("SentientSystems_SetCivic", function()
	it("sends the chooser's request for a civic the player can research", function()
		local env = Load()

		assert.equal("{\"ok\":true}", env.SentientSystems_SetCivic(0, "CIVIC_MYSTICISM"))
		assert.same({ Request(env, env.GameInfo.Civics.CIVIC_MYSTICISM, "PROGRESS_CIVIC", "PARAM_CIVIC_TYPE") }, env.requests)
	end)

	it("fails for a civic the player can't research yet", function()
		local env = Load()

		assert.equal(Failed("CIVIC_THEOLOGY isn't one of the civics you can research now. Use the type of an option of the civics choice."), env.SentientSystems_SetCivic(0, "CIVIC_THEOLOGY"))
		assert.same({}, env.requests)
	end)
end)
