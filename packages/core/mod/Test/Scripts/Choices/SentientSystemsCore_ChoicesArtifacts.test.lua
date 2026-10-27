local FakeGame = require("FakeGame")
local Game = require("Game")

-- Returns the artifact choice JSON for player 0, or nil when it is left out, with an archaeologist
-- digging the artifact given, of the site type given, and the player's blockers, the artifact
-- blocker when missing.
local function ChoicesWith(artifact, blockers)
	local env = Game.new()
	local archaeologist = artifact and { id = 2686995, name = "LOC_UNIT_NAME_REMO", x = 48, y = 25, artifact = artifact }

	FakeGame.Install(env, {
		players = {
			[0] = { archaeologist = archaeologist, playerName = "LOC_LEADER_TRAJAN_NAME", blockers = blockers or { "ENDTURN_BLOCKING_ARTIFACT" } },
			[62] = { playerName = "LOC_LEADER_FREE_CITIES_NAME" },
		},
		text = { LOC_UNIT_NAME_REMO = "Remo", LOC_LEADER_TRAJAN_NAME = "Trajan", LOC_LEADER_FREE_CITIES_NAME = "Free Cities" },
	})
	Game.run(env, "Scripts/Choices/SentientSystemsCore_Choices.lua")

	return env.SentientSystems_GetChoices(0):match("\"artifacts\":(%b[])")
end

describe("SentientSystems_GetArtifactChoices", function()
	it("offers both players' artifacts from a battlefield", function()
		assert.equal(
			"[{\"archaeologist\":2686995,\"description\":\"LOC_CHOOSE_ARTIFACT_EXPLANATION_BATTLE_FOUGHT(Remo,Trajan,Free Cities)\",\"era\":\"ERA_INDUSTRIAL\",\"name\":\"Remo\","
				.. "\"options\":[{\"name\":\"Trajan\",\"player\":0},{\"name\":\"Free Cities\",\"player\":62}],\"x\":48,\"y\":25}]",
			ChoicesWith({ index = 9, type = 3, acting = 0, target = 62, era = "ERA_INDUSTRIAL" })
		)
	end)

	it("offers the one player's artifact from a tribal village", function()
		assert.truthy(ChoicesWith({ index = 32, type = 1, acting = 0, era = "ERA_ANCIENT" }):find(
			"\"description\":\"LOC_CHOOSE_ARTIFACT_EXPLANATION_GOODY_HUT(Remo,Trajan)\",\"era\":\"ERA_ANCIENT\",\"name\":\"Remo\",\"options\":[{\"name\":\"Trajan\",\"player\":0}]",
			1,
			true
		))
	end)

	it("offers both players for a site of a kind the screen doesn't name", function()
		assert.truthy(ChoicesWith({ index = 7, type = 9, acting = 0, target = 62, era = "ERA_ANCIENT" }):find("LOC_CHOOSE_ARTIFACT_EXPLANATION_NO_TYPE", 1, true))
	end)

	it("is left out with no archaeologist digging, and reads nothing without the blocker", function()
		assert.is_nil(ChoicesWith(nil))
		assert.is_nil(ChoicesWith({ index = 9, type = 3, acting = 0, target = 62, era = "ERA_INDUSTRIAL" }, {}))
	end)
end)
