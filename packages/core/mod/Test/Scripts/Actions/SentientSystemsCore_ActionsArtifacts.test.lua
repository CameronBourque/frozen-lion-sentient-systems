local FakeGame = require("FakeGame")
local Game = require("Game")
local Helpers = require("Helpers")

local Failed = Helpers.Failed

local BATTLE = { index = 9, type = 3, acting = 0, target = 62, era = "ERA_INDUSTRIAL" }
local VILLAGE = { index = 32, type = 1, acting = 0, era = "ERA_ANCIENT" }
local NO_ARTIFACT = "You have no artifact to choose. The artifacts choice lists one once an archaeologist digs."

-- Returns an environment with the actions loaded, where player 0 has an
-- archaeologist digging the artifact given and the blockers given, the artifact
-- blocker when missing.
local function Load(artifact, blockers)
	local env = Game.new()
	local archaeologist = artifact and { id = 2686995, name = "LOC_UNIT_NAME_REMO", x = 48, y = 25, artifact = artifact }

	FakeGame.Install(env, {
		players = { [0] = { archaeologist = archaeologist, blockers = blockers or { "ENDTURN_BLOCKING_ARTIFACT" } }, [62] = {} },
	})
	Game.run(env, "Scripts/Actions/SentientSystemsCore_Actions.lua")

	return env
end

-- Returns the request the screen sends for the player.
local function Request(env, artifactPlayer)
	local P = env.PlayerOperations

	return { { player = 0, operation = P.CHOOSE_ARTIFACT_PLAYER, parameters = { [P.PARAM_PLAYER_ONE] = artifactPlayer } } }
end

describe("SentientSystems_ChooseArtifact", function()
	it("sends the screen's request for either player of a battlefield", function()
		for _, chosen in ipairs({ 0, 62 }) do
			local env = Load(BATTLE)

			assert.equal("{\"ok\":true}", env.SentientSystems_ChooseArtifact(0, chosen))
			assert.same(Request(env, chosen), env.requests)
		end
	end)

	it("sends the acting player for a site with one player", function()
		local env = Load(VILLAGE)

		assert.equal("{\"ok\":true}", env.SentientSystems_ChooseArtifact(0, 0))
		assert.same(Request(env, 0), env.requests)
	end)

	it("fails for a player the artifact doesn't offer", function()
		local cases = { { VILLAGE, 62 }, { BATTLE, 5 }, { BATTLE, "62" } }

		for _, case in ipairs(cases) do
			local env = Load(case[1])

			assert.equal(
				Failed("Player " .. case[2] .. " isn't one of this artifact's players. Use a player from the artifacts choice."),
				env.SentientSystems_ChooseArtifact(0, case[2])
			)
			assert.same({}, env.requests)
		end
	end)

	it("fails with no archaeologist digging, or without the blocker", function()
		assert.equal(Failed(NO_ARTIFACT), Load(nil).SentientSystems_ChooseArtifact(0, 0))
		assert.equal(Failed(NO_ARTIFACT), Load(BATTLE, {}).SentientSystems_ChooseArtifact(0, 0))
	end)

	it("fails for an ID with no player", function()
		assert.equal(Failed("ChooseArtifact failed: no player 3"), Load(BATTLE).SentientSystems_ChooseArtifact(3, 0))
	end)
end)
