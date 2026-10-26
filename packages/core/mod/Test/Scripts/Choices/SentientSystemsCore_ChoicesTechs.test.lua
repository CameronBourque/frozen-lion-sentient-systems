local FakeGame = require("FakeGame")
local Game = require("Game")

local SAILING = {
	type = "TECH_SAILING",
	cost = 25,
	turns = 1,
	boost = { percent = 40, trigger = "LOC_BOOST_TRIGGER_SAILING", triggered = false },
	unlocks = { "UNIT_GALLEY", "IMPROVEMENT_FISHING_BOATS" },
}

-- Returns the tech choice JSON for player 0, whose techs are given.
local function TechsWith(techs)
	local env = Game.new()

	FakeGame.Install(env, { players = { [0] = { techs = techs } }, text = { LOC_BOOST_TRIGGER_SAILING = "Found a city on the Coast." } })
	Game.run(env, "Scripts/Choices/SentientSystemsCore_Choices.lua")

	return env.SentientSystems_GetChoices(0):match("\"techs\":(%b[])")
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

describe("SentientSystems_GetTechChoices", function()
	it("lists each tech the player can research, with cost, turns, boost, and unlocks", function()
		assert.equal(
			"[{\"boost\":{\"percent\":40,\"trigger\":\"Found a city on the Coast.\",\"triggered\":false},\"cost\":25,\"turns\":1,"
				.. "\"type\":\"TECH_SAILING\",\"unlocks\":[\"UNIT_GALLEY\",\"IMPROVEMENT_FISHING_BOATS\"]}]",
			TechsWith({ options = { SAILING } })
		)
	end)

	it("leaves out the boost of a tech with none, and gives an empty list of unlocks", function()
		assert.equal("[{\"cost\":12,\"turns\":1,\"type\":\"TECH_MINING\",\"unlocks\":[]}]", TechsWith({ options = { { type = "TECH_MINING", cost = 12, turns = 1 } } }))
	end)

	it("marks a triggered boost, the tech in research, its progress, and the advisor's recommendation", function()
		local techs = TechsWith({
			current = "TECH_SAILING",
			options = { With(SAILING, { progress = 10, recommended = true, boost = { percent = 40, trigger = "LOC_BOOST_TRIGGER_SAILING", triggered = true } }) },
		})

		assert.truthy(techs:find("\"current\":true", 1, true))
		assert.truthy(techs:find("\"progress\":10", 1, true))
		assert.truthy(techs:find("\"recommended\":true", 1, true))
		assert.truthy(techs:find("\"triggered\":true", 1, true))
	end)

	it("leaves out a tech the player can't research yet", function()
		assert.equal("[]", TechsWith({ options = { With(SAILING, { locked = true }) } }))
	end)

	it("lists the tech in research even when CanResearch refuses it", function()
		assert.truthy(TechsWith({ current = "TECH_SAILING", options = { With(SAILING, { locked = true }) } }):find("TECH_SAILING", 1, true))
	end)

	it("lists more than one tech, in the game's order", function()
		local techs = TechsWith({ options = { SAILING, { type = "TECH_MINING", cost = 12, turns = 1 } } })

		assert.truthy(techs:find("TECH_SAILING.*TECH_MINING"))
	end)

	it("gives no unlocks when the game's unlocks file is missing", function()
		local env = Game.new()

		FakeGame.Install(env, { players = { [0] = { techs = { options = { SAILING } } } } })
		env.GetUnlockablesForTech = nil
		Game.run(env, "Scripts/Choices/SentientSystemsCore_Choices.lua")

		assert.is_nil(env.SentientSystems_GetChoices(0):find("unlocks", 1, true))
	end)

	it("adds the tech's description, which the chooser shows as a special unlock", function()
		local env = Game.new()

		FakeGame.Install(env, {
			players = { [0] = { techs = { options = { { type = "TECH_SAILING", cost = 25, turns = 1, description = "LOC_TECH_SAILING_DESCRIPTION" } } } } },
			text = { LOC_TECH_SAILING_DESCRIPTION = "Allows units to embark." },
		})
		Game.run(env, "Scripts/Choices/SentientSystemsCore_Choices.lua")

		assert.truthy(env.SentientSystems_GetChoices(0):find("\"description\":\"Allows units to embark.\"", 1, true))
	end)
end)
